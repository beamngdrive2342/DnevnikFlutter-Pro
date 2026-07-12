# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo layout

The actual Flutter project lives in **`src/`**, not the repo root. Always `cd src` (or prefix commands) before running Flutter/Dart tooling. The repo root only holds project memory/docs (`docs/`, `logs/`, `AGENTS.md`, `index.md`).

```
DnevnikFlutter/
├── AGENTS.md         # Contract with the AI agent — read this first, it is authoritative
├── docs/wiki/         # PROJECT_CONTEXT.md (product/data model), DECISIONS.md (ADRs)
├── logs/sessions/     # Session logs, one per work session
└── src/                # Flutter app (see below)
```

**Before starting non-trivial work, read `AGENTS.md` at the repo root** — it defines hard rules (never touch `.env`/`firestore.rules` without permission, never add pubspec dependencies without approval, always ask before big architectural moves) and a reporting format. This CLAUDE.md is a technical supplement to it, not a replacement.

Also skim `docs/wiki/PROJECT_CONTEXT.md` (data model, feature list) and the tail of `docs/wiki/DECISIONS.md` (recent architectural decisions with rationale) before touching data/auth/AI code — several past attempts (push notifications, raw SVG for geometry, `flutter_math_fork`) were tried and reverted; check there before re-proposing them.

## Commands

All commands run from `src/`:

```bash
cd src
flutter pub get                                          # install deps
dart run build_runner build --delete-conflicting-outputs # regenerate freezed/*.g.dart after model changes
flutter analyze                                           # lint (flutter_lints)
flutter test                                               # run all unit/widget tests
flutter test test/date_utils_test.dart                     # run a single test file
flutter test test/date_utils_test.dart --plain-name "some test name"  # single test case
flutter run                                                 # run the app (device/emulator)
```

There is no Makefile/task runner — these `flutter`/`dart` CLI invocations are the whole workflow. `pubspec.yaml` pins Dart SDK `^3.8.0`, `flutter_riverpod ^3.3.2`, `go_router ^17.3.0`, `freezed ^3.2.5`.

## Architecture

State management is **Riverpod 3** and navigation is **go_router**; there is no `setState`-driven business logic and no `Navigator.push` — don't introduce either.

### `src/lib/` structure
- `data/` — models + services, the only layer that talks to the network:
  - `schedule_data.dart` — `Lesson`/`HomeworkItem` freezed models, `ClassSchedule` (static, app-wide singleton for the currently loaded class's schedule/subjects/times, populated via `ClassSchedule.load(...)` after login)
  - `firestore_service.dart` — CRUD for homework, talks to Firestore **REST API directly** (`https://firestore.googleapis.com/v1/...`), not FlutterFire. Firestore's typed JSON format (`stringValue`, `mapValue`, `arrayValue`, ...) is parsed by hand — see `ClassSchedule.loadFromFirestoreDoc` for the pattern.
  - `auth_service.dart` — Firebase Auth, tokens stored in `flutter_secure_storage` (not `SharedPreferences`)
  - `ai_service.dart` — Gemini calls routed through a Vercel proxy (`src/vercel-proxy/`), never call the Google AI endpoint directly — the API key lives server-side only
- `providers/` — Riverpod `@riverpod` controllers/state (e.g. `auth_provider.dart`, `profile_provider.dart`)
- `router/app_router.dart` — single `GoRouter` instance with auth-based `redirect` logic
- `screens/` — one screen per route, generally paired with a provider
- `widgets/` — shared UI components; custom design-system widgets (`PremiumCard`, `ShimmerLoading`, `ScaleTapWrapper`, etc.) replace stock Material widgets for the "Sahara Warm Minimalism" look — reuse these instead of `Card`/raw `Material` widgets
- `theme/` — colors/text styles/`ThemeController`; no hardcoded colors in screens
- `utils/app_date_utils.dart` — single source of truth for all homework-deadline date formatting/parsing (`formatDateIso`, `parseHomeworkDeadline`, `isHomeworkExpired`). Don't reimplement date formatting elsewhere. Pure functions that depend on "now" take an optional `{DateTime? now}` for deterministic testing.

### Data model (Firestore)
```
/classes/{classId}/                     # className, schoolName, code, schedule map, subjects, lessonTimes
/classes/{classId}/homework/{hwId}/     # subject, task, deadline ("YYYY-MM-DD"), imageUrls[], fullResolutionUrls[], fromSchedule
```
Students join a class via a short code; a class's schedule/homework are fully isolated by `classId`. Homework is cached in memory (~20s TTL) and on disk (`SharedPreferences`, key `offline_homework_{classId}`) for offline use — see `docs/wiki/DECISIONS.md` (2026-06-18) before changing cache invalidation.

### Testing
Tests live in `src/test/` and cover pure logic only (date utils, schedule/homework JSON parsing, AI response parsing) — no network or Firestore calls in tests. Private methods that need direct testing are exposed via a `@visibleForTesting` public wrapper rather than making them public outright (see `FirestoreService.homeworkFromFirestore`, `AIService.extractQuickHomeworkJson`).

### Codegen
Any change to a `@freezed`/`@JsonSerializable` model (`schedule_data.dart`, etc.) requires re-running `dart run build_runner build --delete-conflicting-outputs` — the `.freezed.dart` and `.g.dart` files are generated, don't hand-edit them.
