# Defense notes

Plain-English explainers for every major piece of the WILL app. These are meant for someone who is an engineer but not a software specialist — so the language stays simple, with diagrams and examples instead of jargon.

Every document follows the same template:

- **What it does** — the purpose in one paragraph.
- **How it works** — high-level explanation.
- **Why we built it this way** — the tradeoffs we considered.
- **Why this fits our scope** — how it serves the project.
- **Example / walkthrough** — a concrete example (when useful).
- **Where to look** — files in the codebase.
- **Further reading** — outside resources.

## Contents

1. [Project structure](01-project-structure.md) — how the codebase is organized.
2. [Storage](02-storage.md) — where the app keeps data.
3. [Firebase](03-firebase.md) — the cloud backend.
4. [Prediction layer](04-prediction-layer.md) — how raw sensor data becomes insights.
5. [Random Forest](05-random-forest.md) — the machine learning algorithm we use.
6. [Bluetooth](06-bluetooth.md) — how the phone talks to the wristband.
7. [History and sync](07-history-and-sync.md) — local cache, upload queue, Firestore batches.
8. [Care and reminders](08-care-and-reminders.md) — hydration, medications, insight alerts.

More documents will be added as we build the rest of the app (BLE, reminders, history, sync, etc.).
