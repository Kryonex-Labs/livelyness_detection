# Versions, SDK & dependency updates

> **Summary (for AI):** Dart SDK `>=3.4.3 <4.0.0` (never bumped); Flutter via FVM channel
> `stable`, resolved to 3.22.2; lints = `flutter_lints` only; no CI; package version `0.0.1+5`
> (`+N` used as patch counter). Dependency table below. Only **one** dependency-bump commit
> (`bdc6aa2`: camerawesome/rxdart/flutter_lints); the SDK/Flutter constraints have never moved.

## SDK / Flutter / FVM

| Thing | Value | Notes |
|---|---|---|
| Dart SDK constraint | `>=3.4.3 <4.0.0` | set at first commit, never changed |
| Flutter env floor | `>=1.17.0` | unchanged |
| FVM pin (`.fvmrc`) | `stable` | a **channel**, not a numeric version — not reproducibly pinned |
| Resolved FVM SDK | Flutter 3.22.2 / Dart 3.4.3 | from `.fvm/version`; matches the SDK floor |
| Lints | `flutter_lints` only | `analysis_options.yaml` is two lines; no custom_lint |
| CI | none | `.github/` has issue/PR templates, no `workflows/` |
| Package version | `0.0.1+5` | `+N` build-metadata used as the patch counter |

## Package dependencies (`pubspec.yaml`)

| Package | Constraint | Role |
|---|---|---|
| google_mlkit_face_detection | `^0.11.0` | face detection (the core) |
| camera | `^0.11.0+1` | camera feed — iOS/V1 |
| camerawesome | `^2.1.0` | camera feed — Android/V2 |
| animate_do | `^3.3.4` | step-card transitions |
| lottie | `^3.1.2` | intro animation |
| rxdart | `^0.28.0` | `BehaviorSubject` face-frame stream (V2) |
| path_provider | `^2.0.14` | temp dir for captured photo |
| uuid | `^4.4.2` | capture filenames |
| equatable | `^2.0.5` | declared on `DetectionThreshold`, effectively unused |
| collection | `^1.17.0` | `firstWhereOrNull` |
| image | `^4.0.15` | (declared) |
| plugin_platform_interface | `^2.1.3` | only used by the dead method-channel files |
| **dev:** flutter_lints | `^4.0.0` | |

Example app (`example/pubspec.yaml`) consumes the package via `path: ../` and adds
`google_fonts`, `cupertino_icons`, plus its own `lottie`/`collection`. Its `collection`
floor (`^1.16.0`) is a minor below the package's `^1.17.0` — inconsistent but resolves fine.

## Version-bump history (from git)

- **`7e1c7ca` — Initial Commit.** pubspec created: SDK `>=3.4.3 <4.0.0`, Flutter `>=1.17.0`,
  `camerawesome ^2.0.1`, `rxdart ^0.27.7`, `flutter_lints ^3.0.0`, version `0.0.1`.
- **`bdc6aa2` (2024-09-05) — "feat: Version upgrades…"** the only dependency-bump commit:
  `camerawesome ^2.0.1 → ^2.1.0`, `rxdart ^0.27.7 → ^0.28.0`, `flutter_lints ^3.0.0 → ^4.0.0`,
  package `0.0.1+4 → 0.0.1+5`. Merged via PR #18 (`c382317`).

The SDK/Flutter constraints have **never** been bumped — only these three packages moved.

## CHANGELOG summary

`0.0.1+5` camerawesome/rxdart bump · `0.0.1+4` class renames + show-facial-vertices example ·
`0.0.1+3` docs + head-turn-right fix (issue #8) · `0.0.1+2` hide-vertices config, front camera ·
`0.0.1+1` README · `0.0.1` initial release.

> Note: `0.0.1+3` claims to fix "turn right", but V1's `turnRight` operator is still `>` (see
> [known-issues.md](known-issues.md)) — the fix didn't land on the iOS path.
