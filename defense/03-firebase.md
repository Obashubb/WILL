# Firebase

## What it does

Firebase is the **cloud half** of WILL. It handles three things:

1. **Authentication**, users sign in with email and password.
2. **Database (Firestore)**, long-term storage of health readings, insights, and medication logs.
3. **Push notifications (Cloud Messaging)**, alerts that reach the user even when the app is closed (for example, medication reminders).

We do not run our own servers. Firebase is a managed service from Google. We configure it once and it just runs.

## How it works

```
┌──────────────┐      authentication      ┌──────────────────────┐
│    User      │ ◄────────────────────►  │   Firebase Auth      │
│  signs in    │                          │                      │
└──────────────┘                          └──────────────────────┘
                                                    │
┌──────────────┐    read / write data    ┌──────────▼───────────┐
│  Flutter app │ ◄────────────────────►  │   Cloud Firestore    │
│              │                          │  users/{uid}/...     │
└──────────────┘                          └──────────────────────┘
                                                    │
┌──────────────┐  push notification (FCM) ┌─────────▼────────────┐
│  User's      │ ◄────────────────────    │ Firebase Messaging   │
│  phone OS    │                          │                      │
└──────────────┘                          └──────────────────────┘
```

When the app starts it asks Firebase Auth "is this user signed in?". If yes, it knows the user's id (`uid`) and can read or write only their data in Firestore. The data is organized as `users/{uid}/readings`, `users/{uid}/medications`, and so on.

Each user only sees their own data. Firestore enforces this through **security rules**, small text rules that say: "you can only read documents where the path includes your own uid."

## Why we built it this way

**Tradeoff 1, managed (Firebase) vs. self-hosted backend.** We could write our own backend in Python or Node and host it on AWS or DigitalOcean. That gives full control over the code and costs. But it would also mean:

- Building authentication ourselves (password reset, email verification, token refresh).
- Setting up a database server, taking backups, scaling it, patching it.
- Writing the API that the app talks to.
- Setting up push notifications, which requires platform certificates and a notification server.

Firebase gives us all of this for free up to a generous quota, configured in an afternoon. For a final-year project, this is the only sensible choice.

**Tradeoff 2, Firebase vs. Supabase, AWS Amplify, etc.** Other "backend-as-a-service" options exist. Firebase is the most popular and best-documented choice in the Flutter community, with first-party SDKs from Google. The reference projects we follow also use Firebase, so we stay consistent.

**Tradeoff 3, running the ML in the cloud or on the phone.** A natural question: should the AI prediction run on a Firebase server? We chose to run it on the phone instead. Reasons:

- Random Forest models are tiny, inference takes microseconds.
- It works offline.
- The raw health data never leaves the phone, which is better for privacy.
- It saves on cloud costs.

See `04-prediction-layer.md` for more.

## Why this fits our scope

The PRD asks for cloud storage, authentication, and synchronization. Firebase delivers all three out of the box, free to start. We do not need a custom backend or extra developers, which keeps the scope of the project achievable for one final-year student.

## Example walkthrough

A user opens the app for the first time:

1. The app shows a sign-up screen. Ada enters her email and a password.
2. The app calls `FirebaseAuth.instance.createUserWithEmailAndPassword(...)`. Firebase creates the account and returns a user object containing a unique id like `8sH3kJ4...`.
3. The app stores that id locally. Future Firestore writes use the path `users/8sH3kJ4.../readings/...`.
4. Ada wears the band. Readings stream into the phone. Every minute, the app uploads a batch to `users/8sH3kJ4.../readings/{hour-id}`.
5. A week later, Ada opens the app on a new phone. She signs in with the same email. Firebase returns the same uid. The app reads `users/8sH3kJ4.../readings` and shows the same history.

## Current state

- Firebase project: **`will-wristband`** (under `wisdomiyamu@gmail.com`).
- Android app id: `com.blessing.will`; iOS bundle id: `com.blessing.will`.
- Firebase is initialized in `lib/main.dart` before the app starts.
- Auth (Email/Password) and Firestore (test mode) are enabled in the console.
- The app supports **three** entry paths: sign in, create account, and **continue as guest** (a local-only profile that doesn't touch Firebase).
- After authentication or guest setup, first-time users are routed to **Device Setup** before they see the dashboard.
- Routing is handled by `go_router` with a redirect that reads from the `AuthController` and `ProfileService` (see `lib/core/router.dart`).
- Firestore security rules live in `firestore.rules` at the project root. They must be deployed before any production data lands.

## Where to look

- `lib/firebase_options.dart`, auto-generated by `flutterfire configure`. Do not edit by hand.
- `lib/services/auth_service.dart`, thin wrapper around `FirebaseAuth`.
- `lib/services/profile_service.dart`, local profile cache backed by `get_storage`. Stores `AppUser` (signed-in or guest) and device-setup flags.
- `lib/models/app_user.dart`, unified user model (signed-in users *and* guests).
- `lib/view/auth/auth_controller.dart`, GetX controller that tracks the current user, exposes sign-in / sign-up / guest / sign-out, and reconciles Firebase + local state.
- `lib/core/router.dart`, `go_router` with the redirect rule that drives the welcome → onboarding → home flow.
- `lib/view/auth/welcome_screen.dart`, `login_screen.dart`, `signup_screen.dart`, `guest_screen.dart`, the four auth screens.
- `lib/view/onboarding/device_setup_screen.dart`, wearable pairing prompt.
- `firestore.rules`, security rules, ready to deploy.
- `lib/services/sync_service.dart`, *planned* wrapper around `cloud_firestore` (Phase 4).
- The Firebase Console: https://console.firebase.google.com/project/will-wristband/overview

## Further reading

- [Firebase + Flutter overview](https://firebase.google.com/docs/flutter/setup)
- [Firestore data model](https://firebase.google.com/docs/firestore/data-model)
- [Free-tier limits](https://firebase.google.com/pricing)
