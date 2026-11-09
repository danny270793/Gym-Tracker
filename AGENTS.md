# Agent instructions

Instructions for AI and human collaborators using tools such as **Cursor** and **Claude** in this repository.

## Project structure

The repo holds the Flutter app in `flutter/`. Run Flutter commands from `flutter/` (prefix with `asdf exec`, see `flutter/.tool-versions`).

The app follows the same layout and conventions as the sibling **Wallet** and **MMA-ScoreCard** apps:

```
flutter/lib/
  core/
    auth/auth_session_notifier.dart     # Supabase auth -> ChangeNotifier + CurrentUser (user id for storage)
    date/week.dart                      # Monday-based week helpers
    di/injection.dart                   # get_it registrations (setupDi)
    locale/app_locale_controller.dart   # ChangeNotifier: language preference
    theme/app_theme_controller.dart     # ChangeNotifier: theme preference
    units/app_weight_unit_controller.dart # lb/kg display preference (storage is always lb)
    security/app_biometric_unlock_controller.dart # biometric unlock preference
    storage/local_json_store.dart       # per-user offline cache + downloaded photos on the device
    storage/json_list_cache.dart        # offline copy of a list of entities
    storage/legacy_local_data_migrator.dart # one-time upload of device-only data
    network/offline_error.dart          # which errors mean no connection
    storage/serial_queue.dart           # serializes read-modify-write saves
    logger/app_logger.dart
  features/<feature>/                   # auth, exercises, plan, workouts, dashboard
    data/{datasources,repositories}
    domain/{entities,repositories,usecases}
    presentation/{bloc,cubit,pages}
  l10n/                                 # app_en.arb / app_es.arb + generated app_localizations*.dart
  pages/                                # screens (dashboard, workouts, plan, exercises, settings, legal_info, ...)
  widgets/                              # shared widgets (bottom_sheet_pinned_title, developer_info_section, charts, ...)
  router.dart                           # go_router: /login, 4-tab StatefulShellRoute, detail routes, /settings
  main.dart                             # dev proxy cert (debug), Supabase init, DI, data upload gate, per-user cubits, biometric lock
```

- State management: `get_it` + `flutter_bloc` (Cubit/Bloc) for features; `ChangeNotifier` controllers for locale/theme/weight unit/biometric.
- **Supabase holds auth, data and photos.** Tables are prefixed `gym_` and live in the sibling `supabase` repo (`supabase/migrations/*_gym_tracker*.sql`, docs in `docs/gym/schema.md`). Never add migrations here; change the schema there. Routines and workouts are saved through the `gym_save_routine` / `gym_save_workout` RPCs (app JSON shape in, children replaced in one transaction). Photos go to the private bucket `gym-exercise-images` under `<userId>/`.
- Remote datasources (`*SupabaseDatasource`) sit behind repositories that keep an offline read cache (`JsonListCache` / `LocalJsonStore`, `cache_*.json`) and return `Cached<T>` (`fromCache` drives the offline banner). Writes need a connection. Sign-out clears the cache.
- `LegacyLocalDataMigrator` uploads data left by the device-only first version once per account (run by `_UserDataGate` in `main.dart` before the cubits load).
- `ExercisesCubit`, `PlanCubit` and `WorkoutsCubit` are provided above the router in `main.dart`, keyed by user id, so every route can read them and switching accounts reloads them.
- Loads are stored as numbers: pounds for `LoadType.weight` (convert only for display with `WeightUnit`), a disc count for `LoadType.discs`. Format with `LoadDisplay`.
- Navigation uses `go_router` (`context.push('/settings')`, `/settings/about|privacy|terms`, `/workout/:id`, `/routine/new|:id`, `/exercise/new|:id|:id/edit|:id/progress`).
- Localization: edit `flutter/lib/l10n/app_en.arb` and `app_es.arb`, then run `asdf exec flutter gen-l10n` (see `l10n.yaml`).
- Before finishing a change: `asdf exec flutter analyze` and `asdf exec flutter test`.

## Git commits and branches: explicit user approval is required

**Never commit changes to git unless the user explicitly asks you to.** Make all code changes, then wait for the user to request a commit before running any `git commit` command. Proposing a commit message is fine; running the commit is not.

**Never create a git branch unless the user explicitly asks you to.** Do not run `git branch` or `git checkout -b` (or equivalent) on your own, even to prepare for a commit or Merge Request.

## Pull Requests: use the project template

When creating a GitHub Pull Request, always fill in the description using [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md). GitHub loads that file automatically. Replace each `<!-- … -->` comment with concrete content based on the actual changes. Do not leave placeholder comments in the final description.

## Commits: Conventional Commits (required)

Every commit message **must** follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

### Format

```
<type>[optional scope]: <short description>

[optional body]

[optional footer(s)]
```

- **Description:** imperative mood, lowercase start (a trailing period is not required, but stay consistent).
- **Maximum header length:** keep the first line at ≤ **72** characters when possible.

### Allowed types (common)

Use one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

- **`feat`:** new user-facing behavior or capability.
- **`fix`:** a bug fix.
- **`docs`:** documentation only.
- **`chore`:** maintenance that is not a user-facing feature or fix (dependencies, configuration, tooling).
- **`ci`:** CI/CD pipeline or automation only.

### Scope (optional)

A noun in parentheses after the type, e.g. `fix(postgres): handle null connection string`.

### Breaking changes

Either of:

- add **`!`** after the type/scope: `feat(api)!: remove legacy endpoint`, or
- add a footer: `BREAKING CHANGE: <what changed and what to do>`.

### Examples (valid)

- `feat(examples): add from-code compose sample`
- `fix(ci): use non-tls dind for self-hosted runners`
- `docs: clarify WAL-G vs backup-push in readme`
- `chore: bump gitlab-ci docker image tags`

### Examples (invalid — do not use)

- `Update dockerfile` (missing type)
- `Fixed bug` (not conventional)
- `WIP` / `misc changes`

When proposing or creating commits, **always** use this format. If there are multiple unrelated changes, **split them into several commits** instead of one vague message.
