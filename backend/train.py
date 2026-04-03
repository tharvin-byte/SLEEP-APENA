#!/usr/bin/env python3
"""
Sleep Apnea Detection — CNN Training Script (Fixed Labeling + Class Balance)
=============================================================================
Key fixes:
  1. Correct overlap-based labeling using apnea_events.csv
  2. Class imbalance handled via sklearn compute_class_weight → passed to fit()
  3. Label distribution diagnostic after labeling
"""

import os
import random
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    classification_report, confusion_matrix, roc_auc_score
)
from sklearn.utils.class_weight import compute_class_weight

import tensorflow as tf
from tensorflow.keras import layers, models, callbacks

# ─── Reproducibility ──────────────────────────────────────────────────────────

SEED = 42
random.seed(SEED)
np.random.seed(SEED)
tf.random.set_seed(SEED)

# ─── Configuration ────────────────────────────────────────────────────────────

CFG = {
    "csv_path":         os.path.join("sleep_apnea_dataset", "segments.csv"),
    "events_csv_path":  os.path.join("sleep_apnea_dataset", "apnea_events.csv"),
    "spec_dir":         os.path.join("sleep_apnea_dataset", "spectrograms"),
    "model_dir":        "models",
    "target_shape":     (128, 128),
    "test_size":        0.20,
    "batch_size":       32,
    "epochs":           10,
    "learning_rate":    1e-3,
    "patience":         7,
    "dropout_rate":     0.40,
}

# ─── FIX 1: Correct overlap-based labeling ────────────────────────────────────

def is_apnea(segment_start: float, segment_end: float,
             apnea_events: pd.DataFrame) -> int:
    """
    Returns 1 if the segment overlaps (even partially) with any apnea event.
    Overlap condition:  NOT (seg_end < apnea_start  OR  seg_start > apnea_end)
    This correctly handles all edge cases including partial overlaps.
    """
    for _, row in apnea_events.iterrows():
        if not (segment_end   < row["apnea_event_start_time"] or
                segment_start > row["apnea_event_end_time"]):
            return 1
    return 0


def compute_labels_from_events(segments_df: pd.DataFrame,
                                events_df: pd.DataFrame) -> pd.DataFrame:
    """
    Re-labels every segment in segments_df using correct overlap logic
    against the apnea events CSV.  Works recording-by-recording for
    efficiency on large datasets (avoids O(N*M) full cross-join).

    Parameters
    ----------
    segments_df : DataFrame with columns [segment_id, recording_id,
                                           start_time, end_time, label, spec_path]
    events_df   : DataFrame with columns [recording_id,
                                           apnea_event_start_time,
                                           apnea_event_end_time]
    Returns
    -------
    segments_df with 'label' column corrected in-place (copy returned).
    """
    df = segments_df.copy()
    df["label"] = 0   # reset; will fill correctly below

    for rec_id, seg_group in df.groupby("recording_id"):
        rec_events = events_df[events_df["recording_id"] == rec_id]

        if rec_events.empty:
            # No events for this recording → all segments stay 0
            continue

        labels = seg_group.apply(
            lambda row: is_apnea(row["start_time"], row["end_time"], rec_events),
            axis=1
        )
        df.loc[seg_group.index, "label"] = labels.values

    return df

# ─── FIX 2: Label diagnostic ──────────────────────────────────────────────────

def print_label_distribution(df: pd.DataFrame, stage: str = "") -> None:
    counts = df["label"].value_counts().sort_index()
    total  = len(df)
    tag    = f" [{stage}]" if stage else ""
    print(f"\n📊  Label distribution{tag}:")
    for lbl, cnt in counts.items():
        name = "Apnea  (1)" if lbl == 1 else "Normal (0)"
        print(f"     {name} : {cnt:6d}  ({100*cnt/total:.1f}%)")
    if 1 not in counts or counts[1] == 0:
        print("  ⚠️  WARNING: No apnea samples found! Check events CSV and "
              "overlap logic.")
    elif counts.get(0, 0) / max(counts.get(1, 1), 1) > 10:
        print("  ⚠️  Class imbalance detected — class weights will be applied.")

# ─── FIX 3: Class weight computation ─────────────────────────────────────────

def get_class_weights(labels: np.ndarray) -> dict:
    """
    Uses sklearn to compute balanced class weights.
    Returned dict is passed directly to model.fit(class_weight=...).
    """
    classes = np.unique(labels)
    weights = compute_class_weight(
        class_weight = "balanced",
        classes      = classes,
        y            = labels
    )
    cw = {int(c): float(w) for c, w in zip(classes, weights)}
    print(f"\n⚖️   Class weights: {cw}")
    return cw

# ─── 1. Data Loading ──────────────────────────────────────────────────────────

def load_metadata(csv_path: str, spec_dir: str) -> pd.DataFrame:
    """Read CSV, resolve spectrogram paths, and drop rows with missing files."""
    df = pd.read_csv(csv_path)
    df["spec_path"] = df["segment_id"].apply(
        lambda sid: os.path.join(spec_dir, f"seg_{int(sid):08d}.npy")
    )
    before = len(df)
    df = df[df["spec_path"].apply(os.path.exists)].reset_index(drop=True)
    missing = before - len(df)
    if missing:
        print(f"  ⚠  Skipped {missing} rows — spectrogram file(s) not found.")
    print(f"  ✔  Loaded metadata: {len(df)} valid segments  "
          f"({df['label'].sum()} apnea / {(df['label']==0).sum()} normal)")
    return df

# ─── 2. Preprocessing ─────────────────────────────────────────────────────────

def preprocess_spectrogram(path: str, target_shape: tuple) -> np.ndarray:
    """Load .npy, resize/pad to target_shape, normalise → (H, W, 1) float32."""
    spec = np.load(path).astype(np.float32)

    th, tw = target_shape
    h, w   = spec.shape[:2]

    if (h, w) != (th, tw):
        if h < th:
            spec = np.pad(spec, ((0, th - h), (0, 0)), mode="constant")
        else:
            spec = spec[:th, :]
        if w < tw:
            spec = np.pad(spec, ((0, 0), (0, tw - w)), mode="constant")
        else:
            spec = spec[:, :tw]

    mn, mx = spec.min(), spec.max()
    if mx - mn > 1e-9:
        spec = (spec - mn) / (mx - mn)
    else:
        spec = np.zeros((th, tw), dtype=np.float32)

    return spec[..., np.newaxis]


class ApneaDataset(tf.keras.utils.Sequence):
    """Keras-compatible generator — loads spectrograms on-the-fly."""

    def __init__(self, df: pd.DataFrame, cfg: dict, shuffle: bool = True):
        self.df      = df.reset_index(drop=True)
        self.cfg     = cfg
        self.shuffle = shuffle
        self.indices = np.arange(len(self.df))
        if self.shuffle:
            np.random.shuffle(self.indices)

    def __len__(self) -> int:
        return int(np.ceil(len(self.df) / self.cfg["batch_size"]))

    def __getitem__(self, idx: int):
        batch_idx = self.indices[
            idx * self.cfg["batch_size"] : (idx + 1) * self.cfg["batch_size"]
        ]
        rows  = self.df.iloc[batch_idx]
        specs = np.stack([
            preprocess_spectrogram(row.spec_path, self.cfg["target_shape"])
            for _, row in rows.iterrows()
        ])
        labels = rows["label"].values.astype(np.float32)
        return specs, labels

    def on_epoch_end(self):
        if self.shuffle:
            np.random.shuffle(self.indices)

# ─── 3. Train-Test Split ──────────────────────────────────────────────────────

def split_data(df: pd.DataFrame, cfg: dict):
    """Stratified 80/20 split preserving class balance."""
    train_df, test_df = train_test_split(
        df,
        test_size    = cfg["test_size"],
        random_state = SEED,
        stratify     = df["label"],
    )
    print(f"  Train: {len(train_df)} samples  |  Test: {len(test_df)} samples")
    return train_df, test_df

# ─── 4. Model Architecture (unchanged) ───────────────────────────────────────

def build_model(input_shape: tuple, dropout_rate: float,
                learning_rate: float) -> tf.keras.Model:
    inp = layers.Input(shape=input_shape, name="spectrogram_input")

    x = layers.Conv2D(32, (3, 3), padding="same", activation="relu")(inp)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(32, (3, 3), padding="same", activation="relu")(x)
    x = layers.MaxPooling2D((2, 2))(x)
    x = layers.Dropout(dropout_rate / 2)(x)

    x = layers.Conv2D(64, (3, 3), padding="same", activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(64, (3, 3), padding="same", activation="relu")(x)
    x = layers.MaxPooling2D((2, 2))(x)
    x = layers.Dropout(dropout_rate / 2)(x)

    x = layers.Conv2D(128, (3, 3), padding="same", activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(128, (3, 3), padding="same", activation="relu")(x)
    x = layers.MaxPooling2D((2, 2))(x)
    x = layers.Dropout(dropout_rate)(x)

    x = layers.Conv2D(256, (3, 3), padding="same", activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D((2, 2))(x)
    x = layers.Dropout(dropout_rate)(x)

    x   = layers.GlobalAveragePooling2D()(x)
    x   = layers.Dense(256, activation="relu")(x)
    x   = layers.Dropout(dropout_rate)(x)
    x   = layers.Dense(64,  activation="relu")(x)
    out = layers.Dense(1,   activation="sigmoid", name="apnea_prob")(x)

    model = models.Model(inp, out, name="SleepApneaCNN")
    model.compile(
        optimizer = tf.keras.optimizers.Adam(learning_rate=learning_rate),
        loss      = "binary_crossentropy",
        metrics   = ["accuracy",
                     tf.keras.metrics.AUC(name="auc"),
                     tf.keras.metrics.Precision(name="precision"),
                     tf.keras.metrics.Recall(name="recall")],
    )
    return model

# ─── 5. Callbacks (unchanged) ─────────────────────────────────────────────────

def make_callbacks(model_path: str, patience: int) -> list:
    return [
        callbacks.ModelCheckpoint(
            filepath       = model_path,
            monitor        = "val_loss",
            save_best_only = True,
            mode           = "min",
            verbose        = 1,
        ),
        callbacks.EarlyStopping(
            monitor              = "val_loss",
            patience             = patience,
            restore_best_weights = True,
            verbose              = 1,
        ),
        callbacks.ReduceLROnPlateau(
            monitor  = "val_loss",
            factor   = 0.5,
            patience = max(3, patience // 2),
            min_lr   = 1e-6,
            verbose  = 1,
        ),
    ]

# ─── 6. Evaluation (unchanged) ────────────────────────────────────────────────

def evaluate_model(model: tf.keras.Model,
                   test_df: pd.DataFrame,
                   cfg: dict) -> None:
    print("\n" + "=" * 60)
    print("EVALUATION ON TEST SET")
    print("=" * 60)

    y_true, y_prob = [], []
    for path, label in zip(test_df["spec_path"], test_df["label"]):
        spec = preprocess_spectrogram(path, cfg["target_shape"])[np.newaxis]
        prob = model.predict(spec, verbose=0)[0, 0]
        y_true.append(label)
        y_prob.append(prob)

    y_true = np.array(y_true)
    y_prob = np.array(y_prob)
    y_pred = (y_prob >= 0.5).astype(int)

    print("\nClassification Report:")
    print(classification_report(y_true, y_pred,
                                target_names=["Normal (0)", "Apnea (1)"]))

    cm = confusion_matrix(y_true, y_pred)
    print("Confusion Matrix:")
    print(f"  TN={cm[0,0]}  FP={cm[0,1]}")
    print(f"  FN={cm[1,0]}  TP={cm[1,1]}")

    roc_auc = roc_auc_score(y_true, y_prob)
    print(f"\nROC-AUC Score : {roc_auc:.4f}")

# ─── 7. Plot (unchanged) ──────────────────────────────────────────────────────

def plot_history(history, out_dir: str) -> None:
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    axes[0].plot(history.history["accuracy"],     label="Train Acc",  linewidth=2)
    axes[0].plot(history.history["val_accuracy"], label="Val Acc",    linewidth=2)
    axes[0].set_title("Accuracy", fontsize=14)
    axes[0].set_xlabel("Epoch"); axes[0].set_ylabel("Accuracy")
    axes[0].legend(); axes[0].grid(True, alpha=0.3)

    axes[1].plot(history.history["loss"],     label="Train Loss", linewidth=2)
    axes[1].plot(history.history["val_loss"], label="Val Loss",   linewidth=2)
    axes[1].set_title("Loss", fontsize=14)
    axes[1].set_xlabel("Epoch"); axes[1].set_ylabel("Binary Cross-Entropy")
    axes[1].legend(); axes[1].grid(True, alpha=0.3)

    plt.suptitle("Sleep Apnea CNN — Training History", fontsize=16, y=1.02)
    plt.tight_layout()
    plot_path = os.path.join(out_dir, "training_history.png")
    plt.savefig(plot_path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  📊  Training plot saved → {plot_path}")

# ─── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    cfg = CFG
    Path(cfg["model_dir"]).mkdir(parents=True, exist_ok=True)
    model_path = os.path.join(cfg["model_dir"], "best_model.h5")

    print("=" * 60)
    print("  Sleep Apnea Detection — CNN Training  (Fixed Labeling)")
    print("=" * 60)

    # ── 1. Load metadata ───────────────────────────────────────────────────
    print("\n[1] Loading metadata …")
    df = load_metadata(cfg["csv_path"], cfg["spec_dir"])
    print_label_distribution(df, stage="original CSV labels")

    # ── FIX: Re-label using correct overlap logic from events CSV ──────────
    print("\n[1b] Re-labeling segments using apnea events CSV …")
    events_df = pd.read_csv(cfg["events_csv_path"])
    print(f"  ✔  Loaded {len(events_df)} apnea events across "
          f"{events_df['recording_id'].nunique()} recordings.")

    df = compute_labels_from_events(df, events_df)
    print_label_distribution(df, stage="after overlap-based re-labeling")

    # ── Sample for balanced 50-50 training ───────────────────────────────────
    # Use minimum available samples from either class for true 50-50 balance
    normal_count = len(df[df['label'] == 0])
    apnea_count = len(df[df['label'] == 1])
    min_samples = min(normal_count, apnea_count)
    print(f"  Normal available: {normal_count}, Apnea available: {apnea_count}")
    print(f"  Using min_samples={min_samples} for 50-50 balance")
    
    normal_samples = df[df['label'] == 0].sample(n=min_samples, random_state=42)
    apnea_samples = df[df['label'] == 1].sample(n=min_samples, random_state=42)
    df = pd.concat([normal_samples, apnea_samples]).sample(frac=1, random_state=42).reset_index(drop=True)
    print(f"\n  Using {len(df)} samples (~{len(df)//32} steps per epoch)")
    print_label_distribution(df, stage="after sampling")

    # ── 2. Split ───────────────────────────────────────────────────────────
    print("\n[2] Splitting dataset …")
    train_df, test_df = split_data(df, cfg)

    # ── FIX: Compute class weights to handle imbalance ─────────────────────
    class_weights = get_class_weights(train_df["label"].values)

    # ── 3. Data generators ─────────────────────────────────────────────────
    print("\n[3] Building data generators …")
    train_gen = ApneaDataset(train_df, cfg, shuffle=True)
    val_gen   = ApneaDataset(test_df,  cfg, shuffle=False)

    # ── 4. Model ───────────────────────────────────────────────────────────
    print("\n[4] Loading or building model …")
    input_shape = (*cfg["target_shape"], 1)
    
    # Try to load previous model for continued training
    if os.path.exists(model_path):
        print("  ✔  Found previous model — loading for continued training …")
        model = tf.keras.models.load_model(model_path)
        # Recompile the model after loading (fixes optimizer state issue)
        model.compile(
            optimizer = tf.keras.optimizers.Adam(learning_rate=cfg["learning_rate"]),
            loss      = "binary_crossentropy",
            metrics   = ["accuracy",
                         tf.keras.metrics.AUC(name="auc"),
                         tf.keras.metrics.Precision(name="precision"),
                         tf.keras.metrics.Recall(name="recall")],
        )
        print("  ✔  Previous model loaded and recompiled successfully!")
    else:
        print("  ✔  No previous model found — building new model …")
        model = build_model(input_shape, cfg["dropout_rate"], cfg["learning_rate"])
    
    model.summary()

    # ── 5. Train (with class weights) ─────────────────────────────────────
    print(f"\n[5] Training (up to {cfg['epochs']} epochs) …")
    cbs = make_callbacks(model_path, cfg["patience"])

    history = model.fit(
        train_gen,
        validation_data = val_gen,
        epochs          = cfg["epochs"],
        callbacks       = cbs,
        class_weight    = class_weights,   # ← FIX: penalise majority class
        verbose         = 1,
    )

    # ── 6. Evaluate ────────────────────────────────────────────────────────
    print("\n[6] Loading best model for evaluation …")
    best_model = tf.keras.models.load_model(model_path)
    evaluate_model(best_model, test_df, cfg)

    # ── 7. Plot ────────────────────────────────────────────────────────────
    print("\n[7] Saving training history plot …")
    plot_history(history, cfg["model_dir"])

    print(f"\n✅  Best model saved → {model_path}")
    print("=" * 60)


if __name__ == "__main__":
    main()