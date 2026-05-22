"""
Train the Will Random Forest and export it to assets/ml/model.json.

Usage
-----
1. Drop a labelled CSV at tools/data/samples.csv with columns:
     hr_mean,hr_slope,spo2_min,temp_max,motion_var,label
   where `label` is one of: normal, stress, dehydration, abnormal_oxygen.
   If the CSV is missing the script falls back to synthetic data so the
   rest of the pipeline still works.

2. From the project root:
     python tools/train_model.py

3. Reload the app — InferenceService loads assets/ml/model.json at startup.

The exported JSON uses the same schema the Dart inference engine reads:

    {
      "version": 1,
      "labels":   ["normal", "stress", "dehydration", "abnormal_oxygen"],
      "features": ["hr_mean","hr_slope","spo2_min","temp_max","motion_var"],
      "trees":    [ <nested split / leaf nodes> ]
    }
"""

import csv
import json
import os
import random
from pathlib import Path

try:
    import numpy as np
    from sklearn.ensemble import RandomForestClassifier
except ImportError as exc:
    raise SystemExit(
        "scikit-learn and numpy are required. Install with:\n"
        "    pip install scikit-learn numpy"
    ) from exc

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "tools" / "data" / "samples.csv"
OUT = ROOT / "assets" / "ml" / "model.json"

LABELS = ["normal", "stress", "dehydration", "abnormal_oxygen"]
FEATURES = ["hr_mean", "hr_slope", "spo2_min", "temp_max", "motion_var"]


def load_dataset():
    if not DATA.exists():
        print(f"[warn] {DATA} not found, generating synthetic data.")
        return _synthetic()

    rows = list(csv.DictReader(DATA.open()))
    X = np.array(
        [[float(r[f]) for f in FEATURES] for r in rows], dtype=np.float32
    )
    y = np.array([LABELS.index(r["label"]) for r in rows])
    return X, y


def _synthetic(n_per_class: int = 200):
    random.seed(7)
    X, y = [], []
    for cls, label in enumerate(LABELS):
        for _ in range(n_per_class):
            if label == "normal":
                X.append([
                    random.gauss(78, 6),    # hr_mean
                    random.gauss(0, 0.4),   # hr_slope
                    random.gauss(97, 1),    # spo2_min
                    random.gauss(36.7, 0.1),# temp_max
                    random.uniform(0, 0.3), # motion_var
                ])
            elif label == "stress":
                X.append([
                    random.gauss(108, 6),
                    random.gauss(2.0, 0.5),
                    random.gauss(96, 1),
                    random.gauss(36.8, 0.1),
                    random.uniform(0, 0.05),
                ])
            elif label == "dehydration":
                X.append([
                    random.gauss(95, 5),
                    random.gauss(0.5, 0.4),
                    random.gauss(96, 1),
                    random.gauss(37.5, 0.15),
                    random.uniform(0, 0.05),
                ])
            else:  # abnormal_oxygen
                X.append([
                    random.gauss(95, 8),
                    random.gauss(0.6, 0.6),
                    random.gauss(91, 1),
                    random.gauss(36.9, 0.15),
                    random.uniform(0, 0.2),
                ])
            y.append(cls)
    return np.array(X, dtype=np.float32), np.array(y)


def export_tree(estimator):
    tree = estimator.tree_
    n_classes = len(LABELS)

    def node(i):
        if tree.children_left[i] == -1:
            counts = tree.value[i][0]
            total = counts.sum() or 1
            probs = (counts / total).tolist()
            # Make sure we always emit all 4 labels.
            if len(probs) < n_classes:
                probs = probs + [0.0] * (n_classes - len(probs))
            return {"type": "leaf", "probs": [round(p, 4) for p in probs]}
        return {
            "type": "split",
            "feature": int(tree.feature[i]),
            "threshold": float(round(tree.threshold[i], 4)),
            "left": node(int(tree.children_left[i])),
            "right": node(int(tree.children_right[i])),
        }

    return node(0)


def main():
    X, y = load_dataset()
    clf = RandomForestClassifier(
        n_estimators=8,
        max_depth=5,
        random_state=7,
    )
    clf.fit(X, y)
    print(f"[ok] train accuracy: {clf.score(X, y):.3f}")

    payload = {
        "version": 1,
        "labels": LABELS,
        "features": FEATURES,
        "trees": [export_tree(t) for t in clf.estimators_],
    }
    OUT.write_text(json.dumps(payload, indent=2))
    print(f"[ok] wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
