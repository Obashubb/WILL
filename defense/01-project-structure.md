# Project structure

## What it does

This document explains how the WILL app's code is organized, what each folder is for, and where to look when you want to change something.

## How it works

WILL is a Flutter app. Flutter is a single codebase that builds for both Android and iOS, so we only write the app once.

The top-level folders are:

```
WILL/
├── android/    ← Android wrapper (mostly auto-generated)
├── ios/        ← iOS wrapper (mostly auto-generated)
├── assets/     ← fonts, images bundled into the app
├── docs/       ← product documents (the PRD and implementation plan)
├── defense/    ← these explainer documents (you're reading one)
├── lib/        ← all the Dart code, the actual app
└── pubspec.yaml ← list of external packages the app uses
```

Almost all your time will be spent inside `lib/`:

```
lib/
├── main.dart           ← where the app starts
├── core/               ← shared building blocks
│   ├── colors.dart        the colour palette
│   ├── constants.dart     app name, font name, etc.
│   ├── theme.dart         how the app looks (text sizes, button shapes)
│   ├── assets.dart        names of asset files
│   └── routes.dart        named navigation routes
├── view/               ← all screens and visual widgets
│   ├── home/              the bottom-nav shell and its controller
│   ├── dashboard/         the Dashboard tab
│   ├── history/           the History tab
│   ├── insights/          the Insights tab
│   ├── care/              the Care tab
│   ├── profile/           the Profile tab
│   └── widgets/           shared visual pieces (nav bar, section title)
├── models/             ← data shapes (planned: HealthSample, MedicationDose)
└── services/           ← code that does things (planned: BLE, storage, ML)
```

Three rules to remember:

1. **A screen is one file in `view/<feature>/`.** If you're editing a tab, that's where it lives.
2. **Visual styling comes from `core/theme.dart` + `core/colors.dart`.** Change a colour once and every screen updates.
3. **Code that *does* things (talk to Bluetooth, save to cloud, run ML) goes in `services/`.** Code that *displays* things goes in `view/`.

## Why we built it this way

**Tradeoff 1, folders vs. flat files.** Tiny apps can put every file in one folder. Once a project has more than about ten files, finding things becomes painful. Folders cost a little upfront but pay off as the project grows.

**Tradeoff 2, separating view, model, and service.** We could mix everything, let a screen talk directly to Bluetooth and Firestore. That is faster to write at first. But if we later swap Firebase for something else, we would have to edit every screen. Separation costs a little now and saves a lot later.

**Tradeoff 3, standard Flutter layout.** We follow the layout that Flutter expects, with no clever custom structure. This means anyone who knows Flutter can open the project and find their way around. Being original where it does not help would only confuse a future maintainer or an examiner.

## Why this fits our scope

This is a final-year project that must be **defended in front of examiners** and **editable** if requirements change. So:

- The structure has to be explainable in two minutes. Five top-level folders. Done.
- Editing one screen must feel safe, you should not be afraid of breaking another. The folder layout enforces that.
- The structure must match what examiners expect for a Flutter app, so their attention stays on your work, not your folder names.

## Where to look

- `lib/main.dart`, the entry point (where the app starts).
- `lib/view/home/home_shell.dart`, the bottom-nav scaffold that wraps every tab.
- `lib/view/home/home_controller.dart`, keeps track of which tab is active.
- `pubspec.yaml`, the project's dependency list (packages, fonts, assets).
- `docs/PRD-IMPLEMENTATION.md`, what we are building, in detail.

## Further reading

- [Flutter project structure](https://docs.flutter.dev/get-started/codelab), the official walkthrough.
- [Dart language tour](https://dart.dev/language), the language Flutter uses.
