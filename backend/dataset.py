import numpy as np
import librosa
import os
import csv
import random
from pathlib import Path

# ─── Configuration ────────────────────────────────────────────────────────────

CONFIG = {
    "num_recordings": 5,
    "duration_range": (3600, 10800),   # 1–3 hours in seconds
    "sample_rate": 16000,
    "apnea_events_range": (5, 50),
    "apnea_duration_range": (10, 30),  # seconds
    "window_size": 10,                 # seconds
    "stride": 5,                       # seconds
    "n_mels": 64,
    "n_fft": 512,
    "hop_length": 160,
    "output_dir": "sleep_apnea_dataset",
    "spectrograms_dir": "spectrograms",
    "breathing_freq": 0.3,             # Hz (~18 breaths/min)
    "apnea_amplitude_factor": 0.02,    # near-silence during apnea
}

# ─── Audio Generation ─────────────────────────────────────────────────────────

def generate_breathing_signal(duration_seconds: int, sample_rate: int,
                               breathing_freq: float) -> np.ndarray:
    """Generate a breathing-like sinusoidal signal with noise."""
    t = np.linspace(0, duration_seconds, duration_seconds * sample_rate, endpoint=False)
    # Primary breathing cycle
    breathing = np.sin(2 * np.pi * breathing_freq * t)
    # Harmonic variation
    breathing += 0.3 * np.sin(2 * np.pi * breathing_freq * 2 * t)
    breathing += 0.15 * np.sin(2 * np.pi * breathing_freq * 3 * t)
    # Amplitude modulation to simulate natural variation
    mod_freq = 0.05
    amplitude_mod = 0.8 + 0.2 * np.sin(2 * np.pi * mod_freq * t)
    breathing *= amplitude_mod
    # Add realistic noise
    noise = np.random.normal(0, 0.05, len(t))
    signal = breathing + noise
    # Normalize
    signal = signal / (np.max(np.abs(signal)) + 1e-9)
    return signal.astype(np.float32)

# ─── Apnea Insertion ──────────────────────────────────────────────────────────

def insert_apnea_events(signal: np.ndarray, duration_seconds: int,
                        sample_rate: int, num_events: int,
                        apnea_duration_range: tuple,
                        apnea_amplitude_factor: float) -> tuple[np.ndarray, list]:
    """Insert apnea events into the signal. Returns modified signal and event list."""
    events = []
    signal = signal.copy()

    min_gap = 30  # minimum seconds between events
    occupied = []  # list of (start, end) in seconds

    attempts = 0
    max_attempts = num_events * 20

    while len(events) < num_events and attempts < max_attempts:
        attempts += 1
        apnea_dur = random.uniform(*apnea_duration_range)
        start_sec = random.uniform(60, duration_seconds - apnea_dur - 60)
        end_sec = start_sec + apnea_dur

        # Check overlap with existing events (include gap)
        overlap = False
        for (os_, oe_) in occupied:
            if not (end_sec + min_gap < os_ or start_sec - min_gap > oe_):
                overlap = True
                break
        if overlap:
            continue

        # Apply apnea: taper in, near-silence, taper out
        s_idx = int(start_sec * sample_rate)
        e_idx = int(end_sec * sample_rate)
        event_len = e_idx - s_idx
        taper_len = min(int(0.5 * sample_rate), event_len // 4)

        # Taper in
        taper_in = np.linspace(1.0, apnea_amplitude_factor, taper_len)
        # Taper out
        taper_out = np.linspace(apnea_amplitude_factor, 1.0, taper_len)
        # Middle (near silence)
        middle_len = event_len - 2 * taper_len

        envelope = np.concatenate([
            taper_in,
            np.full(max(middle_len, 0), apnea_amplitude_factor),
            taper_out
        ])
        envelope = envelope[:event_len]  # safety clip

        signal[s_idx:s_idx + len(envelope)] *= envelope

        occupied.append((start_sec, end_sec))
        events.append({
            "start_sec": round(start_sec, 3),
            "end_sec": round(end_sec, 3)
        })

    events.sort(key=lambda x: x["start_sec"])
    return signal, events

# ─── Sliding Window Segmentation ─────────────────────────────────────────────

def segment_signal(duration_seconds: int, window_size: int,
                   stride: int, apnea_events: list) -> list:
    """Generate segment metadata with labels."""
    segments = []
    start = 0.0

    while start + window_size <= duration_seconds:
        end = start + window_size
        # Label = 1 if any apnea event overlaps this window
        label = 0
        for ev in apnea_events:
            if ev["start_sec"] < end and ev["end_sec"] > start:
                label = 1
                break
        segments.append({
            "start_sec": round(start, 3),
            "end_sec": round(end, 3),
            "label": label
        })
        start += stride

    return segments

# ─── Spectrogram Extraction ───────────────────────────────────────────────────

def extract_mel_spectrogram(segment_audio: np.ndarray, sample_rate: int,
                             n_mels: int, n_fft: int,
                             hop_length: int) -> np.ndarray:
    """Compute and normalize a mel spectrogram from an audio segment."""
    mel = librosa.feature.melspectrogram(
        y=segment_audio,
        sr=sample_rate,
        n_fft=n_fft,
        hop_length=hop_length,
        n_mels=n_mels,
        fmin=20,
        fmax=sample_rate // 2
    )
    mel_db = librosa.power_to_db(mel, ref=np.max)
    # Normalize to [0, 1]
    mel_min, mel_max = mel_db.min(), mel_db.max()
    if mel_max - mel_min > 1e-9:
        mel_norm = (mel_db - mel_min) / (mel_max - mel_min)
    else:
        mel_norm = np.zeros_like(mel_db)
    return mel_norm.astype(np.float32)

# ─── Save Outputs ─────────────────────────────────────────────────────────────

def save_spectrogram(spec: np.ndarray, path: str) -> None:
    np.save(path, spec)

def append_segments_csv(writer: csv.DictWriter, recording_id: int,
                         segments: list) -> int:
    """Write segment rows; returns count of segments written."""
    global _segment_counter
    count = 0
    for seg in segments:
        writer.writerow({
            "segment_id": _segment_counter,
            "recording_id": recording_id,
            "start_time": seg["start_sec"],
            "end_time": seg["end_sec"],
            "label": seg["label"]
        })
        _segment_counter += 1
        count += 1
    return count

def append_events_csv(writer: csv.DictWriter, recording_id: int,
                       events: list) -> None:
    for ev in events:
        writer.writerow({
            "recording_id": recording_id,
            "apnea_event_start_time": ev["start_sec"],
            "apnea_event_end_time": ev["end_sec"]
        })

_segment_counter = 0

# ─── Main Pipeline ────────────────────────────────────────────────────────────

def process_recording(recording_id: int, cfg: dict,
                       spec_dir: Path,
                       seg_writer: csv.DictWriter,
                       evt_writer: csv.DictWriter) -> dict:
    """Generate one recording, extract features, and save incrementally."""
    sr = cfg["sample_rate"]
    duration = random.randint(*cfg["duration_range"])
    num_events = random.randint(*cfg["apnea_events_range"])

    print(f"  [Recording {recording_id}] duration={duration}s, events={num_events}")

    # 1. Generate base breathing signal
    signal = generate_breathing_signal(duration, sr, cfg["breathing_freq"])

    # 2. Insert apnea events
    signal, events = insert_apnea_events(
        signal, duration, sr, num_events,
        cfg["apnea_duration_range"],
        cfg["apnea_amplitude_factor"]
    )

    # 3. Save event metadata
    append_events_csv(evt_writer, recording_id, events)

    # 4. Segment + extract spectrograms
    segments = segment_signal(duration, cfg["window_size"],
                               cfg["stride"], events)

    seg_count = 0
    for seg in segments:
        s_idx = int(seg["start_sec"] * sr)
        e_idx = int(seg["end_sec"] * sr)
        seg_audio = signal[s_idx:e_idx]

        if len(seg_audio) < cfg["window_size"] * sr:
            seg_audio = np.pad(seg_audio, (0, cfg["window_size"] * sr - len(seg_audio)))

        spec = extract_mel_spectrogram(
            seg_audio, sr, cfg["n_mels"], cfg["n_fft"], cfg["hop_length"]
        )

        global _segment_counter
        seg_id = _segment_counter
        spec_path = spec_dir / f"seg_{seg_id:08d}.npy"
        save_spectrogram(spec, str(spec_path))

        # Write CSV row
        seg_writer.writerow({
            "segment_id": seg_id,
            "recording_id": recording_id,
            "start_time": seg["start_sec"],
            "end_time": seg["end_sec"],
            "label": seg["label"]
        })
        _segment_counter += 1
        seg_count += 1

    # Free memory explicitly
    del signal

    return {
        "recording_id": recording_id,
        "duration": duration,
        "num_events": len(events),
        "num_segments": seg_count
    }


def generate_dataset(cfg: dict = CONFIG) -> None:
    global _segment_counter
    _segment_counter = 0

    out_dir = Path(cfg["output_dir"])
    spec_dir = out_dir / cfg["spectrograms_dir"]
    spec_dir.mkdir(parents=True, exist_ok=True)

    segments_csv_path = out_dir / "segments.csv"
    events_csv_path = out_dir / "apnea_events.csv"

    seg_fields = ["segment_id", "recording_id", "start_time", "end_time", "label"]
    evt_fields = ["recording_id", "apnea_event_start_time", "apnea_event_end_time"]

    print("=" * 60)
    print(f"Generating {cfg['num_recordings']} recordings...")
    print(f"Output directory: {out_dir.resolve()}")
    print("=" * 60)

    with open(segments_csv_path, "w", newline="") as sf, \
         open(events_csv_path, "w", newline="") as ef:

        seg_writer = csv.DictWriter(sf, fieldnames=seg_fields)
        evt_writer = csv.DictWriter(ef, fieldnames=evt_fields)
        seg_writer.writeheader()
        evt_writer.writeheader()

        summary = []
        for rec_id in range(1, cfg["num_recordings"] + 1):
            result = process_recording(
                rec_id, cfg, spec_dir, seg_writer, evt_writer
            )
            summary.append(result)
            print(f"  → {result['num_segments']} segments saved | "
                  f"{result['num_events']} apnea events")

    print("\n" + "=" * 60)
    print("Dataset generation complete.")
    print(f"  Segments CSV : {segments_csv_path}")
    print(f"  Events CSV   : {events_csv_path}")
    print(f"  Spectrograms : {spec_dir}")
    total_segs = sum(r["num_segments"] for r in summary)
    total_events = sum(r["num_events"] for r in summary)
    print(f"  Total segments  : {total_segs}")
    print(f"  Total apnea evts: {total_events}")
    print("=" * 60)


if __name__ == "__main__":
    random.seed(42)
    np.random.seed(42)
    generate_dataset(CONFIG)