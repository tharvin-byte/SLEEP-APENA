#!/usr/bin/env python3
"""
Sleep Apnea Detection — Inference Pipeline
==========================================
Given a long .wav audio file, this module:
  1. Splits audio into overlapping 10-second segments
  2. Converts each segment into a mel spectrogram
  3. Runs CNN inference to predict apnea probability
  4. Merges consecutive apnea predictions into events
  5. Returns detected event count and apnea flag
"""

import os
import numpy as np
import librosa
import tensorflow as tf
from dataclasses import dataclass
from typing import List, Tuple

# ─── Configuration ────────────────────────────────────────────────────────────

CFG = {
    "model_path":      os.path.join("models", "best_model.h5"),
    "sample_rate":     16_000,
    "window_size":     10,          # seconds
    "stride":          5,           # seconds
    "target_shape":    (128, 128),  # (H, W) fed to CNN
    "n_mels":          64,
    "n_fft":           512,
    "hop_length":      160,
    "threshold":       0.5,         # apnea probability threshold
    "min_event_gap":   10,          # seconds — merge events closer than this
    "min_event_dur":   5,           # seconds — drop events shorter than this
}

# ─── Data Structures ──────────────────────────────────────────────────────────

@dataclass
class ApneaEvent:
    index:      int
    start_time: float   # seconds
    end_time:   float   # seconds

    @property
    def duration(self) -> float:
        return self.end_time - self.start_time

# ─── 1. Audio Loading ─────────────────────────────────────────────────────────

def _load_audio(audio_path: str, sample_rate: int) -> Tuple[np.ndarray, float]:
    """
    Load a .wav file at the target sample rate.

    Returns
    -------
    audio        : float32 numpy array, shape (N,)
    duration_sec : total duration in seconds
    """
    if not os.path.exists(audio_path):
        raise FileNotFoundError(f"Audio file not found: {audio_path}")

    audio, sr = librosa.load(audio_path, sr=sample_rate, mono=True)
    duration  = len(audio) / sample_rate
    return audio.astype(np.float32), duration

# ─── 2. Segmentation ──────────────────────────────────────────────────────────

def _segment_audio(audio: np.ndarray,
                   sample_rate: int,
                   window_size: int,
                   stride: int) -> List[Tuple[np.ndarray, float, float]]:
    """
    Split audio into overlapping fixed-length windows.

    Returns
    -------
    List of (segment_audio, start_sec, end_sec)
    """
    win_samples    = window_size * sample_rate
    stride_samples = stride      * sample_rate
    total_samples  = len(audio)
    segments       = []

    start_sample = 0
    while start_sample + win_samples <= total_samples:
        end_sample = start_sample + win_samples
        seg        = audio[start_sample:end_sample]
        start_sec  = start_sample / sample_rate
        end_sec    = end_sample   / sample_rate
        segments.append((seg, start_sec, end_sec))
        start_sample += stride_samples

    # Include final partial segment (zero-padded) if meaningful
    remainder = total_samples - start_sample
    if remainder > sample_rate:   # at least 1 second of audio left
        seg       = np.zeros(win_samples, dtype=np.float32)
        seg[:remainder] = audio[start_sample:]
        start_sec = start_sample / sample_rate
        end_sec   = total_samples / sample_rate
        segments.append((seg, start_sec, end_sec))

    return segments

# ─── 3. Spectrogram Extraction ────────────────────────────────────────────────

def _create_spectrogram(segment: np.ndarray,
                        sample_rate: int,
                        target_shape: Tuple[int, int],
                        n_mels: int,
                        n_fft: int,
                        hop_length: int) -> np.ndarray:
    """
    Compute a normalised mel spectrogram and resize to target_shape.

    Returns
    -------
    spec : float32 array, shape (H, W, 1) — ready for CNN inference
    """
    mel = librosa.feature.melspectrogram(
        y          = segment,
        sr         = sample_rate,
        n_fft      = n_fft,
        hop_length = hop_length,
        n_mels     = n_mels,
        fmin       = 20,
        fmax       = sample_rate // 2,
    )
    mel_db = librosa.power_to_db(mel, ref=np.max).astype(np.float32)

    # ── Resize / pad to target shape ───────────────────────────────────────
    th, tw = target_shape
    h, w   = mel_db.shape

    if h < th:
        mel_db = np.pad(mel_db, ((0, th - h), (0, 0)), mode="constant")
    else:
        mel_db = mel_db[:th, :]

    if w < tw:
        mel_db = np.pad(mel_db, ((0, 0), (0, tw - w)), mode="constant")
    else:
        mel_db = mel_db[:, :tw]

    # ── Min-max normalisation ──────────────────────────────────────────────
    mn, mx = mel_db.min(), mel_db.max()
    if mx - mn > 1e-9:
        mel_db = (mel_db - mn) / (mx - mn)
    else:
        mel_db = np.zeros((th, tw), dtype=np.float32)

    return mel_db[..., np.newaxis]   # (H, W, 1)

# ─── 4. Model Inference ───────────────────────────────────────────────────────

def _predict_segments(segments: List[Tuple[np.ndarray, float, float]],
                      model: tf.keras.Model,
                      cfg: dict) -> List[Tuple[float, float, float, int]]:
    """
    Run CNN inference over all segments in batches.

    Returns
    -------
    List of (start_sec, end_sec, probability, predicted_label)
    """
    batch_size = 32
    results    = []
    total      = len(segments)
    spec_shape = cfg["target_shape"]

    for batch_start in range(0, total, batch_size):
        batch_segs = segments[batch_start : batch_start + batch_size]

        specs = np.stack([
            _create_spectrogram(
                seg, cfg["sample_rate"], spec_shape,
                cfg["n_mels"], cfg["n_fft"], cfg["hop_length"]
            )
            for seg, _, _ in batch_segs
        ])                                        # (B, H, W, 1)

        probs = model.predict(specs, verbose=0).flatten()   # (B,)

        for (seg, start_sec, end_sec), prob in zip(batch_segs, probs):
            label = 1 if prob >= cfg["threshold"] else 0
            results.append((start_sec, end_sec, float(prob), label))

    return results

# ─── 5. Event Detection ───────────────────────────────────────────────────────

def _detect_events(predictions: List[Tuple[float, float, float, int]],
                   min_event_gap: float,
                   min_event_dur: float) -> List[ApneaEvent]:
    """
    Merge consecutive / near-consecutive apnea predictions into events.

    Strategy
    --------
    1. Collect all apnea-positive segment windows.
    2. Merge windows whose gap is ≤ min_event_gap seconds.
    3. Drop merged events shorter than min_event_dur seconds.

    Returns
    -------
    List of ApneaEvent sorted by start_time.
    """
    apnea_windows = [
        (start, end) for start, end, _, label in predictions if label == 1
    ]

    if not apnea_windows:
        return []

    apnea_windows.sort(key=lambda x: x[0])

    # ── Merge overlapping / close windows ─────────────────────────────────
    merged = []
    cur_start, cur_end = apnea_windows[0]

    for start, end in apnea_windows[1:]:
        if start - cur_end <= min_event_gap:
            cur_end = max(cur_end, end)
        else:
            merged.append((cur_start, cur_end))
            cur_start, cur_end = start, end
    merged.append((cur_start, cur_end))

    # ── Filter too-short events ────────────────────────────────────────────
    events = [
        ApneaEvent(index=i + 1, start_time=s, end_time=e)
        for i, (s, e) in enumerate(merged)
        if (e - s) >= min_event_dur
    ]

    return events

# ─── Public API ───────────────────────────────────────────────────────────────

def run_model(audio_path: str, cfg: dict = CFG) -> dict:
    """
    End-to-end sleep apnea inference pipeline.

    Parameters
    ----------
    audio_path : str
        Path to the input .wav audio file.
    cfg : dict, optional
        Configuration overrides. Defaults to module-level CFG.

    Returns
    -------
    dict
        {
            "apnea":          bool  — True if one or more events were detected,
            "events":         int   — total number of detected apnea events,
            "events_per_hour": float — normalised event rate per hour,
            "risk":           str   — severity classification,
            "advice":         str   — user-facing recommendation,
            "events_detail":  list  — per-event start / end / duration in seconds
        }

    Raises
    ------
    FileNotFoundError
        If audio_path or the model file does not exist.
    """
    if not os.path.exists(cfg["model_path"]):
        raise FileNotFoundError(f"Model not found: {cfg['model_path']}")

    model = tf.keras.models.load_model(cfg["model_path"])

    audio, _duration = _load_audio(audio_path, cfg["sample_rate"])

    segments = _segment_audio(
        audio, cfg["sample_rate"], cfg["window_size"], cfg["stride"]
    )

    predictions = _predict_segments(segments, model, cfg)

    events = _detect_events(
        predictions, cfg["min_event_gap"], cfg["min_event_dur"]
    )

    # ── (A) Events per hour ────────────────────────────────────────────────
    events_per_hour = round((len(events) / _duration) * 3600, 2) if _duration > 0 else 0.0

    # ── (B) Risk classification ────────────────────────────────────────────
    if events_per_hour < 5:
        risk = "Normal"
    elif events_per_hour < 15:
        risk = "Mild"
    elif events_per_hour < 30:
        risk = "Moderate"
    else:
        risk = "Severe"

    # ── (C) User-friendly advice ───────────────────────────────────────────
    _advice_map = {
        "Normal":   "No immediate concern",
        "Mild":     "Monitor your sleep and consider lifestyle changes",
        "Moderate": "Consider consulting a doctor",
        "Severe":   "Consult a doctor as soon as possible",
    }
    advice = _advice_map[risk]

    # ── (D) Per-event detail ───────────────────────────────────────────────
    events_detail = [
        {
            "start":    round(ev.start_time, 2),
            "end":      round(ev.end_time, 2),
            "duration": round(ev.duration, 2),
        }
        for ev in events
    ]

    return {
        "apnea":           len(events) > 0,
        "events":          len(events),
        "events_per_hour": events_per_hour,
        "risk":            risk,
        "advice":          advice,
        "events_detail":   events_detail,
    }


# ─── Optional CLI / test entry point ─────────────────────────────────────────

if __name__ == "__main__":
    result = run_model("test_audio/sample.wav")
    print(result)