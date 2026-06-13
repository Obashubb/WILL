import json
import numpy as np
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, ConfusionMatrixDisplay, accuracy_score
from sklearn.model_selection import train_test_split

rng = np.random.default_rng(42)

# Features: [heart_rate, spo2, temperature, motion, perfusion_index, hrv]
# Severity:  0=Normal, 1=Watch, 2=Alert
# Condition: 0=None, 1=Stress, 2=Dehydration, 3=Overexertion

def make(n, hr, spo2, temp, mot, pi, hrv, severity, condition):
    X = np.column_stack([
        rng.uniform(*hr, n),
        rng.uniform(*spo2, n),
        rng.uniform(*temp, n),
        rng.uniform(*mot, n),
        rng.uniform(*pi, n),
        rng.uniform(*hrv, n),
    ])
    y = np.column_stack([np.full(n, severity), np.full(n, condition)])
    return X, y

# Normal — healthy baseline: good HRV, healthy PI
X0, y0 = make(600, (75, 100), (92, 97), (36.1, 37.2), (0.0, 0.3), (1.5, 4.0), (40, 70), 0, 0)

# Stress — HR up, HRV suppressed, temp slightly down, PI normal-ish, low motion
X1, y1 = make(300, (100, 125), (93, 97), (35.8, 36.8), (0.0, 0.4), (1.0, 3.0), (10, 30), 1, 1)

# Dehydration — HR up, SpO2 slightly low, temp up, PI low, HRV mid
X2, y2 = make(300, (100, 120), (88, 93), (37.0, 38.0), (0.0, 0.4), (0.3, 1.2), (25, 50), 1, 2)

# Overexertion — high motion, HR up, SpO2 dipping, PI variable, HRV low-ish
X3, y3 = make(300, (105, 135), (88, 93), (36.5, 37.8), (0.6, 1.0), (1.0, 3.5), (15, 40), 1, 3)

# Alert — severe pattern: very high HR, low SpO2, fever, low PI, low HRV
X4, y4 = make(200, (120, 160), (80, 90), (38.0, 40.0), (0.0, 0.4), (0.2, 1.0), (5, 25), 2, 2)

X = np.vstack([X0, X1, X2, X3, X4])
y = np.vstack([y0, y1, y2, y3, y4])

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

clf = RandomForestClassifier(n_estimators=20, max_depth=6, random_state=42)
clf.fit(X_train, y_train)

train_pred = clf.predict(X_train)
test_pred = clf.predict(X_test)

print(f"Severity  — train: {accuracy_score(y_train[:,0], train_pred[:,0]):.2%}  test: {accuracy_score(y_test[:,0], test_pred[:,0]):.2%}")
print(f"Condition — train: {accuracy_score(y_train[:,1], train_pred[:,1]):.2%}  test: {accuracy_score(y_test[:,1], test_pred[:,1]):.2%}")

print("\nSeverity report:")
print(classification_report(y_test[:,0], test_pred[:,0], target_names=["Normal","Watch","Alert"]))
print("Condition report:")
print(classification_report(y_test[:,1], test_pred[:,1], target_names=["None","Stress","Dehydration","Overexertion"]))

# Feature importance — now shows how much each of the 6 signals contributes
features = ["Heart Rate", "SpO2", "Temperature", "Motion", "Perfusion Index", "HRV"]
plt.figure(figsize=(8, 4))
plt.barh(features, clf.feature_importances_, color="#14B8A6")
plt.xlabel("Importance")
plt.title("WILL — Feature Importance (6 inputs)")
plt.tight_layout()
plt.savefig("c:/StudioProjects/healthapp/docs/feature_importance.png", dpi=150)
plt.close()
print("\nFeature importance saved.")

# Confusion matrices
cm_sev = confusion_matrix(y_test[:,0], test_pred[:,0])
ConfusionMatrixDisplay(cm_sev, display_labels=["Normal","Watch","Alert"]).plot(cmap="Blues")
plt.title("Severity Confusion Matrix")
plt.tight_layout()
plt.savefig("c:/StudioProjects/healthapp/docs/confusion_severity.png", dpi=150)
plt.close()

cm_cond = confusion_matrix(y_test[:,1], test_pred[:,1])
ConfusionMatrixDisplay(cm_cond, display_labels=["None","Stress","Dehydr.","Overex."]).plot(cmap="Greens")
plt.title("Condition Confusion Matrix")
plt.tight_layout()
plt.savefig("c:/StudioProjects/healthapp/docs/confusion_condition.png", dpi=150)
plt.close()
print("Confusion matrices saved.")

def export_tree(tree):
    t = tree.tree_
    return {
        "children_left":  t.children_left.tolist(),
        "children_right": t.children_right.tolist(),
        "feature":        t.feature.tolist(),
        "threshold":      t.threshold.tolist(),
        "value":          [v.tolist() for v in t.value],
    }

model_json = {
    "outputs": ["severity", "condition"],
    "severity_classes":  ["Normal", "Watch", "Alert"],
    "condition_classes": ["None", "Stress", "Dehydration", "Overexertion"],
    "features": ["heart_rate", "spo2", "temperature", "motion", "perfusion_index", "hrv"],
    "trees": [export_tree(e) for e in clf.estimators_],
}

out_path = "c:/StudioProjects/healthapp/assets/ml/model.json"
with open(out_path, "w") as f:
    json.dump(model_json, f)

print(f"Model saved to {out_path}")