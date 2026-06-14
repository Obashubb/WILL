# Random Forest

## What it does

Random Forest is the machine-learning algorithm WILL uses to classify the user's current state from sensor readings. It takes in five or six summary numbers describing a 30-second window of data and outputs a label like "Normal" or "Stress likely."

## How it works

A Random Forest is not one model. It is a **collection of decision trees** that vote.

**What is a decision tree?**

A flowchart of simple yes/no questions. Each branch leads to another question or to a final answer. Example:

```
Is mean HR > 100?
├── Yes → Is min SpO₂ < 93?
│         ├── Yes → Label: Abnormal oxygen
│         └── No  → Label: Stress
└── No  → Is temperature > 37.5?
          ├── Yes → Label: Fever
          └── No  → Label: Normal
```

Each tree is built by a computer during **training**, looking at thousands of labelled examples and finding the best questions to ask at each branch.

**Why a "forest" of trees?**

A single tree can be wrong, especially if the data is noisy. A forest is many different trees, each built from a slightly different slice of the training data, each asking slightly different questions. To make a prediction, every tree casts a vote and the majority wins.

```
Input features  →  Tree 1 says "Stress"
                →  Tree 2 says "Normal"     →  Final = "Stress" (3 of 5)
                →  Tree 3 says "Stress"        Confidence = 3/5 = 0.6
                →  Tree 4 says "Stress"
                →  Tree 5 says "Normal"
```

The fraction of trees that agree gives us our **confidence score**.

## Why we built it this way

**Tradeoff 1, Random Forest vs. a deep neural network.** Neural networks are more powerful for huge datasets (millions of examples) but:

- They need much more data to train well, we will have hundreds, not millions.
- They are heavier to run on a phone.
- They are harder to defend ("why did the network say that?"), they are black boxes.

Random Forest:

- Works well with small datasets.
- Inference is microseconds, just walking simple trees.
- Each tree is human-readable, so we can explain the prediction.

**Tradeoff 2, Random Forest vs. simpler models (e.g. logistic regression).** Logistic regression assumes the features combine in a straight line. Random Forest can capture interactions, for example, "high HR is normal IF motion is high, but dangerous IF motion is low." For health data this matters.

**Tradeoff 3, number of trees.** More trees = more accurate but a bigger model file and slower predictions. Around 50–100 trees is the sweet spot for our problem size.

## Why this fits our scope

The PRD specifies Random Forest. We chose it (and the PRD codifies the choice) because:

- We can train and explain it within a final-year project timeline.
- It runs on a phone with no special hardware.
- It works with the modest dataset we have available.

## Example walkthrough

Suppose we have 100 labelled examples of patient readings. Each example is the set of features over a 30-second window plus the correct label.

**Training (done offline, once, in Python with `scikit-learn`):**

```python
from sklearn.ensemble import RandomForestClassifier

# features: [hr_mean, hr_slope, spo2_min, temp_max, motion_var]
X = [[78, 0.1, 97, 36.7, 0.05], ...]
y = ["Normal", "Stress", "Dehydration", ...]   # labels

model = RandomForestClassifier(n_estimators=50, max_depth=8)
model.fit(X, y)
```

The trained model is then exported to a JSON file that records every tree's structure. The JSON is copied into `assets/ml/model.json` in the Flutter project.

**Inference (done on the phone, many times per minute):**

```dart
final features = [hrMean, hrSlope, spo2Min, tempMax, motionVar];
final result = InferenceService.predict(features);
// → { label: "Stress", confidence: 0.78 }
```

The Dart code loads the JSON once at startup. For every feature set, it walks each tree's questions, collects the votes, and returns the most-voted label with its share of the votes as the confidence.

## Current state

- The first model shipped with the app was hand-crafted (5 trees, depth 3-4) so we could test the full pipeline before any labelled data existed. Each tree looks at the same features from a different angle, HR-focused, SpO₂-focused, temperature-focused, slope-focused, and a combined view. The trees vote and we publish the average probability vector.
- `tools/train_model.py` replaces the hand-crafted model with a real sklearn `RandomForestClassifier` (8 trees, max_depth=5). It reads `tools/data/samples.csv` if present, otherwise falls back to synthetic data with class-conditional Gaussians so the training pipeline still runs.
- The export format matches what `InferenceService` loads, nested split/leaf nodes with `feature`, `threshold`, and per-leaf `probs`.

## Where to look

- `assets/ml/model.json`, the model the app ships with.
- `lib/services/inference_service.dart`, the Dart tree walker (`_walk`) and feature extractor (`_extractFeatures`).
- `tools/train_model.py`, Python training script. Run from the project root: `python tools/train_model.py`.

## Further reading

- [Random Forest, Wikipedia](https://en.wikipedia.org/wiki/Random_forest)
- [scikit-learn RandomForestClassifier docs](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestClassifier.html)
- [Visualizing decision trees](https://mlu-explain.github.io/decision-tree/), interactive explainer.
