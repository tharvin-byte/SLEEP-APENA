#!/usr/bin/env python3
"""
Sleep Apnea Synthetic Data Generator
=====================================
Generates a .wav audio file that simulates a long breathing recording
with randomly inserted apnea events — ready for inference.py
"""

import os
import random
import argparse
import numpy as np
import soundfile as sf
from pathlib import Path

# ─── Configuration ────────────────────────────────────────────────────────────

CFG = {
    "output_dir":              "test_audio",
    "num_recordings":          3,
    "duration_range":          (3600, 7200),   # 1–2 hours in seconds
    "sample_rate":             16000,
    "apnea_events_range":      (10, 40),
    "apnea_duration_range":    (10, 30),        # seconds
    "breathing_freq":          0.3,             # Hz (~18 breaths/min)
    "apnea_amplitude_factor":  0.02,            # near-silence during apnea
    "min_gap_between_events":  30,              # seconds
}

# ─── 1. Breathing Signal Generator ───────────────────────────────────────────

def generate_breathing_signal(duration_seconds: int,
                               sample_rate: int,
                               breathing_freq: float) -> np.ndarray:
    """
    Generate a realistic breathing-like audio signal.
    Combines:
      - Primary sinusoidal breathing cycle
      - Harmonic overtones
      - Slow amplitude modulation (natural breath variation)
      - Gaussian background noise
    """
    t = np.linspace(0, duration_seconds,
                    duration_seconds * sample_rate, endpoint=False)

    # Primary breathing rhythm
    signal  = np.sin(2 * np.pi * breathing_freq * t)
    # First harmonic
    signal += 0.30 * np.sin(2 * np.pi * breathing_freq * 2 * t)
    # Second harmonic
    signal += 0.15 * np.sin(2 * np.pi * breathing_freq * 3 * t)
    # Third harmonic
    signal += 0.08 * np.sin(2 * np.pi * breathing_freq * 4 * t)

    # Slow amplitude modulation — simulates natural breathing depth changes
    mod_freq        = 0.04
    amplitude_mod   = 0.75 + 0.25 * np.sin(2 * np.pi * mod_freq * t)
    signal         *= amplitude_mod

    # Snoring-like bursts (random short-duration high-freq noise)
    snore_mask = np.random.choice([0, 1], size=len(t),
                                   p=[0.997, 0.003]).astype(np.float32)
    snore      = snore_mask * np.random.normal(0, 0.3, len(t))
    signal    += snore

    # Ambient background noise
    noise   = np.random.normal(0, 0.04, len(t))
    signal += noise

    # Normalise to [-1, 1]
    signal = signal / (np.max(np.abs(signal)) + 1e-9)
    return signal.astype(np.float32)

# ─── 2. Apnea Event Inserter ──────────────────────────────────────────────────

def insert_apnea_events(signal: np.ndarray,
                         duration_seconds: int,
                         sample_rate: int,
                         num_events: int,
                         apnea_duration_range: tuple,
                         apnea_amplitude_factor: float,
                         min_gap: int) -> tuple:
    """
    Randomly inserts apnea events into the signal.
    Each event:
      - Has a smooth taper-in and taper-out envelope
      - Reduces amplitude to near-silence during the event
      - Is separated from other events by at least min_gap seconds

    Returns
    -------
    signal : modified audio array
    events : list of dicts with start_sec and end_sec
    """
    signal    = signal.copy()
    events    = []
    occupied  = []   # list of (start, end) in seconds
    attempts  = 0
    max_tries = num_events * 30

    while len(events) < num_events and attempts < max_tries:
        attempts += 1

        apnea_dur = random.uniform(*apnea_duration_range)
        # Keep events away from the very start and end of the recording
        margin    = 120   # 2 minute margin
        start_sec = random.uniform(margin, duration_seconds - apnea_dur - margin)
        end_sec   = start_sec + apnea_dur

        # Check for overlap with existing events including minimum gap
        overlap = any(
            not (end_sec + min_gap < os_ or start_sec - min_gap > oe_)
            for os_, oe_ in occupied
        )
        if overlap:
            continue

        # ── Apply apnea envelope ──────────────────────────────────────────
        s_idx      = int(start_sec * sample_rate)
        e_idx      = int(end_sec   * sample_rate)
        event_len  = e_idx - s_idx
        taper_len  = min(int(1.5 * sample_rate), event_len // 3)

        taper_in   = np.linspace(1.0, apnea_amplitude_factor, taper_len)
        taper_out  = np.linspace(apnea_amplitude_factor, 1.0, taper_len)
        middle_len = max(event_len - 2 * taper_len, 0)
        silence    = np.full(middle_len, apnea_amplitude_factor)

        envelope   = np.concatenate([taper_in, silence, taper_out])
        envelope   = envelope[:event_len]   # safety clip

        signal[s_idx : s_idx + len(envelope)] *= envelope

        occupied.append((start_sec, end_sec))
        events.append({
            "start_sec": round(start_sec, 3),
            "end_sec":   round(end_sec,   3),
            "duration":  round(apnea_dur, 3),
        })

    events.sort(key=lambda x: x["start_sec"])
    return signal, events

# ─── 3. Save Audio ────────────────────────────────────────────────────────────

def save_wav(signal: np.ndarray,
             sample_rate: int,
             output_path: str) -> None:
    """Save a float32 numpy array as a 16-bit PCM .wav file."""
    # Clip to [-1, 1] before writing
    signal = np.clip(signal, -1.0, 1.0)
    sf.write(output_path, signal, sample_rate, subtype="PCM_16")

# ─── 4. Save Event Metadata ───────────────────────────────────────────────────

def save_event_log(events: list,
                   recording_id: int,
                   duration: int,
                   output_path: str) -> None:
    """Save apnea event metadata as a plain-text log file."""
    with open(output_path, "w") as f:
        f.write(f"Recording ID   : {recording_id}\n")
        f.write(f"Duration       : {duration}s  ({duration/3600:.2f} hr)\n")
        f.write(f"Total Events   : {len(events)}\n")
        f.write("-" * 50 + "\n")
        f.write(f"{'#':<5} {'Start (s)':>10} {'End (s)':>10} {'Duration (s)':>13}\n")
        f.write("-" * 50 + "\n")
        for i, ev in enumerate(events, 1):
            f.write(f"{i:<5} {ev['start_sec']:>10.1f} {ev['end_sec']:>10.1f} "
                    f"{ev['duration']:>13.1f}\n")

# ─── 5. Print Summary ─────────────────────────────────────────────────────────

def print_recording_summary(rec_id: int, duration: int,
                             events: list, wav_path: str) -> None:
    print(f"\n  ── Recording {rec_id} ──────────────────────────────")
    print(f"     Duration    : {duration}s  ({duration/3600:.2f} hr)")
    print(f"     Apnea events: {len(events)}")
    if events:
        print(f"     First event : {events[0]['start_sec']:.1f}s → "
              f"{events[0]['end_sec']:.1f}s")
        print(f"     Last event  : {events[-1]['start_sec']:.1f}s → "
              f"{events[-1]['end_sec']:.1f}s")
    print(f"     Saved to    : {wav_path}")

# ─── 6. Main Generator ────────────────────────────────────────────────────────

def generate(cfg: dict) -> None:
    """
    Main generation loop.
    Creates num_recordings synthetic .wav files with embedded apnea events.
    """
    out_dir = Path(cfg["output_dir"])
    out_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("  Sleep Apnea Synthetic Audio Generator")
    print("=" * 60)
    print(f"  Output directory : {out_dir.resolve()}")
    print(f"  Recordings       : {cfg['num_recordings']}")
    print(f"  Duration range   : {cfg['duration_range'][0]//3600}–"
          f"{cfg['duration_range'][1]//3600} hr")
    print(f"  Sample rate      : {cfg['sample_rate']} Hz")
    print(f"  Events per rec   : {cfg['apnea_events_range'][0]}–"
          f"{cfg['apnea_events_range'][1]}")
    print("=" * 60)

    for rec_id in range(1, cfg["num_recordings"] + 1):
        duration   = random.randint(*cfg["duration_range"])
        num_events = random.randint(*cfg["apnea_events_range"])

        print(f"\n[Recording {rec_id}/{cfg['num_recordings']}]  "
              f"duration={duration}s  events={num_events}")

        # ── Generate base breathing signal ────────────────────────────────
        print("  Generating breathing signal …", end=" ", flush=True)
        signal = generate_breathing_signal(
            duration, cfg["sample_rate"], cfg["breathing_freq"]
        )
        print("done")

        # ── Insert apnea events ───────────────────────────────────────────
        print("  Inserting apnea events …", end=" ", flush=True)
        signal, events = insert_apnea_events(
            signal, duration, cfg["sample_rate"],
            num_events,
            cfg["apnea_duration_range"],
            cfg["apnea_amplitude_factor"],
            cfg["min_gap_between_events"],
        )
        print(f"done  ({len(events)} events placed)")

        # ── Save .wav ─────────────────────────────────────────────────────
        wav_filename = f"recording_{rec_id:03d}.wav"
        wav_path     = out_dir / wav_filename
        print("  Saving .wav file …", end=" ", flush=True)
        save_wav(signal, cfg["sample_rate"], str(wav_path))
        print("done")

        # ── Save event log ────────────────────────────────────────────────
        log_path = out_dir / f"recording_{rec_id:03d}_events.txt"
        save_event_log(events, rec_id, duration, str(log_path))

        # ── Summary ───────────────────────────────────────────────────────
        print_recording_summary(rec_id, duration, events, str(wav_path))

        # Free memory
        del signal

    print("\n" + "=" * 60)
    print("  Generation complete!")
    print(f"  Files saved to: {out_dir.resolve()}")
    print("\n  To run inference on a generated file:")
    print(f"    python inference.py {out_dir}/recording_001.wav")
    print("=" * 60 + "\n")


# ─── CLI Entry Point ──────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate synthetic sleep apnea .wav recordings"
    )
    parser.add_argument(
        "--output_dir", type=str, default=CFG["output_dir"],
        help=f"Output directory  (default: {CFG['output_dir']})"
    )
    parser.add_argument(
        "--num_recordings", type=int, default=CFG["num_recordings"],
        help=f"Number of recordings to generate  (default: {CFG['num_recordings']})"
    )
    parser.add_argument(
        "--min_duration", type=int, default=CFG["duration_range"][0],
        help=f"Minimum duration in seconds  (default: {CFG['duration_range'][0]})"
    )
    parser.add_argument(
        "--max_duration", type=int, default=CFG["duration_range"][1],
        help=f"Maximum duration in seconds  (default: {CFG['duration_range'][1]})"
    )
    parser.add_argument(
        "--min_events", type=int, default=CFG["apnea_events_range"][0],
        help=f"Minimum apnea events per recording  (default: {CFG['apnea_events_range'][0]})"
    )
    parser.add_argument(
        "--max_events", type=int, default=CFG["apnea_events_range"][1],
        help=f"Maximum apnea events per recording  (default: {CFG['apnea_events_range'][1]})"
    )
    parser.add_argument(
        "--seed", type=int, default=42,
        help="Random seed for reproducibility  (default: 42)"
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    random.seed(args.seed)
    np.random.seed(args.seed)

    # Override CFG with CLI args
    CFG["output_dir"]           = args.output_dir
    CFG["num_recordings"]       = args.num_recordings
    CFG["duration_range"]       = (args.min_duration, args.max_duration)
    CFG["apnea_events_range"]   = (args.min_events,   args.max_events)

    generate(CFG)