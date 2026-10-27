# Tata Cross-Platform

Flutter application for **Tata**, the VitaHealth product for medication adherence and family follow-up.

## Scope

This repository contains the cross-platform mobile client for Android and iOS. It shares the Tata product scope, design references and REST contracts with the native Android application. The backend remains in `vitaHealth-UPC/web-services`.

## Architecture

One Flutter application, organized by Bounded Context as features are implemented. The architecture separates `domain`, `application`, `infrastructure` and `presentation` responsibilities, with BLoC for presentation state.

The `app` package owns startup, dependency composition and global navigation. Shared technical and visual components belong to `shared`; business rules remain in their owning context.

## Bounded Contexts

| Package | Bounded Context |
| --- | --- |
| `identity_subscription` | Identity & Subscription |
| `care_link` | Care Link |
| `treatment_management` | Treatment Management |
| `intake_execution` | Intake Execution |
| `omission_escalation` | Omission & Escalation |
| `family_monitoring` | Family Monitoring |
| `adherence_analytics` | Adherence Analytics |
| `inventory_replenishment` | Inventory & Replenishment |
| `accessibility_preferences` | Accessibility & Preferences |

## Baseline

- Flutter 3.47.8 stable
- Dart 3.13.7
- Android and iOS platform projects
- Dart package: `tata`
- Application identifier: `com.vitahealth.tata`
- Application version: `0.1.0+1`

The initial scaffold preserves the Android Studio project supplied by the team. It contains the application entry point, a minimal host and its widget test. Context packages are added with their functional flows.

## Run

```sh
flutter pub get
flutter run
```

## Build and test

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

For iOS, use macOS with Xcode:

```sh
flutter build ios --simulator --debug
```

## GitFlow

```text
main
  develop
    feature/us-xx-short-description
```

Feature branches correspond to User Stories. Pull requests target `develop`; release branches integrate into `main`. Use Conventional Commits and Semantic Versioning.
