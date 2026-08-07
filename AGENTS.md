# AGENTS.md — OpenLifts

Conventions for humans and AI agents working in this repo. Read this before
writing code. Keep it current: when a convention changes, update this file in
the same PR.

## What OpenLifts is

A **local-first** mobile app that implements the **StrongLifts 5×5** barbell
strength program — a StrongLifts clone. Flutter, iOS + Android. No backend, no
account, no sync (data lives on-device). See the domain glossary at the bottom
before touching workout logic.

## Tech stack (the house patterns — do not introduce alternatives without updating this file)

| Concern | Choice | Notes |
|---|---|---|
| State management | **Riverpod + codegen** (`@riverpod`) | The house pattern. One exception: repository *stream* providers are hand-written `StreamProvider`s (riverpod_generator can't emit a codegen provider whose type is a Drift part-file class) — see the Data layer section. |
| Models | **freezed** + **json_serializable** | Immutable data classes with `copyWith`, unions, JSON. |
| Navigation | **go_router** | One central route table in `lib/core/router/app_router.dart`. |
| Local data | **Drift (SQLite)** via `drift_flutter` | Wired — see the Data layer section below. |
| Lint | **very_good_analysis** (strict) | `flutter analyze` must pass clean before every commit. (`riverpod_lint`/`custom_lint` are omitted — they pin an analyzer version incompatible with `drift_dev`.) |
| Tests | **flutter_test** | Widget + unit tests mirror the `lib/` path under `test/`. |

## Architecture — feature-first

```
lib/
  main.dart                     # ProviderScope root
  app.dart                      # MaterialApp.router (thin — do not add logic here)
  core/                         # cross-cutting infrastructure
    router/                     # go_router table
    theme/                      # app theme
  shared/                       # reusable, feature-agnostic widgets/utils
  features/
    <feature>/                  # each feature is self-contained
      data/                     # repositories, Drift DAOs, data sources
      domain/                   # freezed models, pure business logic
      application/              # @riverpod controllers/providers (state)
      presentation/             # screens + widgets
```

Rules:

- **A feature owns its folder.** Cross-feature reuse goes through `shared/` or
  `core/`, never by importing another feature's internals.
- **Dependencies point inward:** `presentation` → `application` → `domain`;
  `data` implements `domain` contracts. UI never talks to a data source
  directly — it goes through a provider.
- **Keep `app.dart` and `main.dart` thin.** New behavior belongs in a feature.

## Data layer

Local-first persistence with Drift. Follow these conventions:

- **Schema lives in `lib/core/database/`** — `tables.dart` (table defs +
  enums), `converters.dart` (`TypeConverter`s), `app_database.dart`
  (`@DriftDatabase` + migrations). Feature repositories query it behind domain
  interfaces.
- **Repository seam.** Each feature has `domain/<x>_repository.dart` (an
  `abstract interface class`), `data/<x>_repository_impl.dart` (Drift-backed),
  and `application/<x>_providers.dart`. Repositories return Drift's generated
  row classes directly; a **freezed** model appears only for computed
  aggregates that diverge from a stored row (e.g. `UpcomingWorkout`).
- **Reactive reads** use Drift `.watch()` through Riverpod. The repository
  provider is `@riverpod`; the **stream** provider is a hand-written
  `final xProvider = StreamProvider(...)` (the codegen exception above).
- **Shared database provider:** `appDatabaseProvider` in
  `lib/core/providers/database_provider.dart` (keepAlive). Every repository
  provider reads it.
- **kg is canonical.** Store all weights in kg; convert/round at the edge with
  `lib/core/units/units.dart` (`displayWeight`, `roundToLoadable`). Never store
  pounds.
- **Pure engines have no Drift/Riverpod dependency** — progression
  (`features/progression`), warmup (`features/workout`), set-group resolution
  and rotation/schedule (`features/programs`, `features/home`) are plain Dart,
  unit-tested in isolation.
- **JSON columns via `TypeConverter`** (`StringListConverter`,
  `IntListConverter`) for display-only lists; never blob binary.

### Migrations

Pre-release, the schema is defined wholesale: `schemaVersion` is `1` and
`onCreate` runs `m.createAll()` — no `onUpgrade` steps, since nothing has
shipped to migrate from. Iterate the schema freely by editing `tables.dart`; a
fresh install just recreates it.

Once the app ships, switch to stepwise migrations: for every schema change bump
`schemaVersion` and add an `onUpgrade` step (`if (from < N) await
m.createTable(...)` / `m.addColumn(...)`) — never a destructive reset — plus
drift `SchemaVerifier` migration tests.

### Seeding

Built-in content ships as bundled JSON (`assets/seed/{exercises,programs}.json`).
Seeders take a **JSON string argument** (a fixture via `File(...)` in tests,
`rootBundle` in the app) — see `lib/core/seed/bootstrap.dart`. Idempotent via
slug PKs + `seedVersion`; exercises seed before programs (FK order). Call
`ensureSeededFromAssets(db)` once at startup.

### Testing

In-memory Drift only — `openTestDb()` in `test/support/test_database.dart`
(`AppDatabase(NativeDatabase.memory())`). **Never mock the database.** Import
generated companions (`ExercisesCompanion`, `SettingsCompanion`, …) from
`app_database.dart`, **not** from `package:drift` — they're generated, not part
of drift (a common mistake).

## State management rules (Riverpod codegen)

- Declare all providers with the `@riverpod` annotation and run codegen:

  ```dart
  part 'workout_controller.g.dart';

  @riverpod
  class WorkoutController extends _$WorkoutController {
    @override
    Workout build() => Workout.initial();

    void logSet(SetEntry entry) => state = state.addSet(entry);
  }
  ```

- Business logic lives in the controller/notifier, **not** in widgets.
- Widgets read state with `ref.watch(...)` and trigger changes with
  `ref.read(....notifier)`. Convert a `StatelessWidget` to a
  `ConsumerWidget` (or use `Consumer`) to get a `ref`.
- After adding or changing any `@riverpod`, `@freezed`, or `@JsonSerializable`
  code, **run build_runner** (see commands) or the app won't compile.

## Localization

The UI supports **English + Mongolian** via Flutter's official `gen-l10n`
tooling. Conventions:

- **Every user-facing string goes through `AppLocalizations`**, never a raw
  string literal in a widget. In a widget: `AppLocalizations.of(context)!.key`.
  In an `application`-layer provider (no `BuildContext`), watch
  `appLocalizationsProvider` (`lib/features/settings/application/settings_providers.dart`).
- **Source of truth is `lib/l10n/app_en.arb`** (the template); add the same key
  to `lib/l10n/app_mn.arb` in the same change — mismatched keys fail codegen.
  Run `flutter gen-l10n` (or `flutter pub get`, which triggers it via
  `generate: true` in `pubspec.yaml`) after editing either file.
- **Plurals** use ICU plural syntax in the `.arb` entry
  (`{count, plural, one{...} other{...}}`) — Mongolian has no plural
  inflection, so its translation only needs an `other` form.
- **Exception**: the 37-exercise catalog (`assets/seed/exercises.json`, names +
  instructions) is intentionally English-only for now — it's seeded data, not
  UI chrome, and translating it needs a separate locale-aware reseed mechanism.
- **Language selection** is manual (Settings → Language: System/Монгол/English),
  stored in `Settings.languageMode` (mirrors the existing `themeMode` pattern)
  and resolved to a `Locale?` by `localeProvider`.
- **Widget tests**: wrap the widget under test with `wrapWithLocalizations()`
  from `test/support/test_app.dart` instead of a bare `MaterialApp(home: ...)`
  — without the delegate, `AppLocalizations.of(context)!` throws.

## Comments

Comment the **why**, not the **what** — the code already says what it does. A
good comment captures a non-obvious decision, a constraint, or a gotcha the next
reader would trip on. Keep them useful and brief.

- **One or two lines.** If a comment needs a paragraph, the code may be the
  problem. Explain the reasoning, not a play-by-play of each statement.
- **Say it once.** Don't repeat the same rationale on the caller, the callee,
  and the helper. Document it where the logic lives; elsewhere, point to it
  (`// See [recalcFromEditedSet].`).
- **No narration.** Drop comments that echo the next line (`// increment i`),
  restate a name, or label obvious structure.
- **A clear name beats a comment.** Rename the murky thing instead of annotating
  it.
- **Doc comments (`///`)** on public APIs state the contract and edge cases
  (nulls, throws, units) — not the implementation retold in prose.
- Keep comments true: update or delete them when the code changes.

## Commands

A `Makefile` wraps the common flows (run `make` to list targets). Codegen
output (`*.g.dart`, `*.freezed.dart`) is git-ignored, so a fresh clone must
generate it before the app compiles — `make setup` does deps + codegen + hooks
in one shot, and `make watch` keeps codegen running during development.

```bash
make setup            # fresh clone: pub get + build_runner + activate git hooks
make watch            # continuous codegen — run in a second terminal while developing
make check            # format + analyze + test (the definition of done)
make run-android      # boot the `openlifts` emulator and launch on it
make run              # launch on the default device
```

The underlying commands, if you prefer to run them directly:

```bash
# One-time, after installing the Flutter SDK — generates android/ + ios/
# without overwriting the hand-authored lib/ and configs:
flutter create --platforms=android,ios --org com.openlifts .

flutter pub get                                             # dependencies
dart run build_runner build                                 # codegen (run after editing annotated code)
dart run build_runner watch                                 # codegen, continuous
dart format .                                               # format (run before commit)
flutter analyze                                             # lint — must pass clean
flutter test                                                # tests
flutter run                                                 # launch on a device/simulator
```

## Git hooks

Version-controlled hooks live in `.githooks/` (activated via
`git config core.hooksPath .githooks` — run once per clone; it's in the setup
steps). They mirror CI so red never reaches the remote:

- **pre-commit** → `dart format` (check) + `flutter analyze` on staged Dart.
- **pre-push** → `flutter test`.

Skip with `--no-verify` if you must; CI still catches it on the PR.

After a pull or branch switch, run `make setup` (or `flutter pub get` +
`dart run build_runner build`) if pubspec or annotated code changed, so the
git-ignored generated files don't go stale.

## Definition of done (every change)

1. `dart format .` applied.
2. `flutter analyze` passes with **zero** issues.
3. `flutter test` passes; new behavior has a test.
4. If annotated code changed, codegen was re-run and the app builds.
5. `AGENTS.md` updated if a convention changed.

## Testing conventions

- Test files mirror the source path: `lib/features/x/y.dart` →
  `test/features/x/y_test.dart`.
- Override providers via `ProviderScope(overrides: …)` in widget tests; use an
  in-memory Drift DB (`openTestDb()`), never a mocked one.
- In a widget test, override the screen's async provider with a fixed value —
  a real async DB read leaves a spinner animating and hangs `pumpAndSettle`.
  Put DB round-trips in a plain `test()` with a `ProviderContainer`.
- Structure tests arrange → act → assert; one behavior per test.

## Generated code

`*.g.dart`, `*.freezed.dart` are **git-ignored** and regenerated by
build_runner (CI runs it before analyze/test). Never edit generated files by
hand.

## Commit conventions

Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`,
`chore:`, `ci:`. One logical change per commit. Keep the app green
(`analyze` + `test`) on every commit.

## Do / Don't for agents

**Do**
- Follow the feature-first layout and put new features under `lib/features/`.
- Use `@riverpod` codegen for all state.
- Keep changes local to a feature; reuse via `shared/`/`core/`.
- Comment the *why*, briefly — see [Comments](#comments).
- Run format + analyze + test before declaring work done.

**Don't**
- Introduce a second state-management library or manual providers.
- Put business logic in widgets or in `app.dart`.
- Import one feature's internals from another feature.
- Write comments that narrate the code or repeat a rationale stated elsewhere.
- Edit generated (`*.g.dart` / `*.freezed.dart`) files.
- Add a backend, auth, or network sync — this app is local-first by design.

## StrongLifts 5×5 domain glossary

Implement the program to these rules (they drive future features):

- **Program:** two alternating workouts, 3×/week (e.g. Mon/Wed/Fri), never two
  days in a row. Weeks look like A-B-A, then B-A-B.
- **Workout A:** Squat, Bench Press, Barbell Row.
- **Workout B:** Squat, Overhead Press, Deadlift.
- **5×5:** 5 sets of 5 reps for each lift — **except Deadlift, which is 1×5**
  (one work set of 5).
- **Sets & reps:** a *set* is one group of reps; a *rep* is one repetition. A
  session logs the actual reps completed per set (5 = success).
- **Linear progression:** on a successful lift (all sets × reps completed), add
  **+2.5 kg** (or +5 lb) next session for that lift. Deadlift often adds +5 kg.
- **Failure:** not completing all reps of all sets. Repeat the same weight next
  session.
- **Deload:** after **3 consecutive failed sessions** on a lift, reduce its
  working weight by **10%** and climb back up.
- **Warmup sets:** lighter ramp-up sets before the working sets (typically
  2–5, empty bar upward); they are not counted toward 5×5 progression.
- **Working weight:** the load used for the counted 5×5 work sets.

Units: support **kg and lb**; increments differ by unit (2.5 kg / 5 lb).
