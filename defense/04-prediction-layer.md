# Prediction layer

## What it does

The wearable sends raw sensor numbers — heart rate, oxygen, temperature, motion. By themselves, these are just data points. The **prediction layer** turns them into **meaning**: "you look stressed," "you might be dehydrated," "your oxygen looks abnormal."

It is the bridge between sensor data and the user's understanding.

## How it works

The flow has three stages:

```
┌────────────────────────┐   ┌─────────────────────────┐   ┌────────────────────┐
│ 1.  Sample collection  │ → │ 2.  Feature extraction  │ → │ 3.  Classification │
│   raw bytes from band  │   │   means, ranges, slopes │   │   Random Forest →  │
│                        │   │   over a 30-second win  │   │   label + score    │
└────────────────────────┘   └─────────────────────────┘   └────────────────────┘
```

**Stage 1 — sample collection.** Every reading from the band is added to a rolling buffer that holds the last 30 seconds of data.

**Stage 2 — feature extraction.** Raw numbers alone do not predict much. We compute simple summary numbers — called **features** — over the window:

- Average heart rate
- Minimum SpO₂
- Maximum body temperature
- Standard deviation of motion (how much the user is moving)
- Slope (is heart rate going up?)

This is the same idea as RMS or peak-to-peak in signal processing: condense a noisy signal into a few descriptive numbers.

**Stage 3 — classification.** The set of features is fed into a trained Random Forest model (see `05-random-forest.md`). The model returns:

- A **label** — Normal, Stress, Dehydration, Abnormal oxygen.
- A **confidence score** — between 0 and 1, how sure the model is.

The label is shown on the Insights tab. If the score is high *and* the label is concerning, an alert is raised (vibration on the wearable, push notification on the phone).

## Why we built it this way

**Tradeoff 1 — fixed rules vs. a trained model.** We could write simple if-then rules ("if HR > 120 then alert"). Rules are easy to read and explain. But:

- The thresholds for sickle cell patients vary by person and by what they are doing.
- Multiple sensors *in combination* predict crises better than any one alone.
- A model can learn these combinations from data.

The model is a bit harder to defend ("why did it say that?") but more accurate. To compensate, we expose the confidence score so the app stays transparent.

**Tradeoff 2 — running on the phone vs. in the cloud.** Already discussed in `03-firebase.md`. The phone wins because the model is tiny and we want low-latency, offline-capable insights.

**Tradeoff 3 — a 30-second window vs. a longer history.** Shorter window = faster reaction, more false alarms. Longer window = more stable but slow to react. Thirty seconds is the balance used in similar wearable studies.

## Why this fits our scope

- The PRD asks for "intelligent recommendations" — a rule-based system would be limiting.
- The classifier must run offline — on-device inference is the only fit.
- We have time to train one model on the labelled data we collect (or synthesize for the prototype), but not time to build a real-time cloud inference pipeline.

## Example walkthrough

The band has been on Ada's wrist for the last 30 seconds.

| Time | HR | SpO₂ | Temp | Motion |
|---|---|---|---|---|
| 0 s | 78 | 97 | 36.7 | low |
| 5 s | 84 | 96 | 36.7 | low |
| ... | ... | ... | ... | ... |
| 30 s | 112 | 92 | 37.0 | high |

**Feature extraction**

- HR mean: 95
- HR slope: +1.1 bpm/sec (rising fast)
- SpO₂ min: 92 (low end of normal)
- Temp max: 37.0 (slight elevation)
- Motion variance: high

**Classification**

The Random Forest looks at these five numbers, walks through its decision trees, and returns:

- Label: **Stress likely**
- Confidence: 0.78

**What the app then does**

- Shows on the Insights tab: "Your heart rate climbed quickly and your oxygen dipped. This often happens during stress or physical exertion. If you're at rest, consider sitting down and breathing slowly."
- Logs the insight to Firestore for history.
- If confidence had been higher (say > 0.9) and the label was a crisis pattern, it would also vibrate the band and push a notification.

## Where to look

- `lib/services/inference_service.dart` — planned location of the prediction pipeline.
- `assets/ml/model.json` — planned location of the trained model (loaded at startup).
- `05-random-forest.md` — how the classifier itself works.

## Further reading

- [Feature engineering for time series](https://en.wikipedia.org/wiki/Feature_engineering) — Wikipedia overview.
- [Random Forests for biomedical signals](https://scholar.google.com/scholar?q=random+forest+wearable+sickle+cell) — search starting point.
