# Gym Tracker

Plan your training week, log every workout against that plan, and see your progress.

Flutter **3.47.2** (see [`.tool-versions`](.tool-versions)). Android/iOS package: `io.github.danny270793.gym_tracker`.

## Quick start

```sh
cp .env.example.json .env.json   # then fill in real values (same Supabase project as the other apps)
# the gym_ migration must be applied to that project first (supabase repo: supabase db push)
asdf exec flutter pub get
asdf exec flutter run --dart-define-from-file=.env.json
```

Or `scripts/start.sh [-d <device>]` / `scripts/build.sh --platform android|ios --mode debug|release`.

## Features

- **Exercises**: reusable entities with the muscles they train directly (count 1 set) and secondary muscles (count ½ set), equipment, how-to notes and reference photos (camera or gallery).
- **Plan**: routines (e.g. *Push*: 3×8 incline dumbbell press, 3×8 dumbbell shoulder press, 3×8 triceps cable pushdown) assigned to weekdays. A routine can be used on several days.
- **Workouts**: today's planned routine is one tap away. The log starts as a copy of the plan, with weights from your last session, then you can drop exercises, change sets/reps/weight or add new exercises. Check sets as you do them; only checked sets count. Changes save automatically.
- **Dashboard**: this week's workouts vs plan, volume, reps and sets with change vs last week; weekly volume and reps for 8 weeks; sets per muscle; strength trends (best estimated 1RM, last 4 weeks vs previous 4); personal records; streak and average duration. Each exercise also has a progress chart (1RM, top weight, volume, reps).
- **Settings**: change email/password, biometric unlock, language (system/English/Spanish), theme, weight unit (lb/kg), about, privacy, terms, sign out.

## Data

Supabase holds the account, the data and the photos. The schema lives in the [supabase](https://github.com/danny270793/Supabase) repo with the other apps' schemas (prefix `gym_`). See [`docs/gym/schema.md`](https://github.com/danny270793/Supabase/blob/main/docs/gym/schema.md) there:

- Tables: `gym_exercises`, `gym_routines` + `gym_routine_exercises`, `gym_weekly_plan`, `gym_workouts` + `gym_workout_exercises` + `gym_workout_sets`, all with RLS per user.
- Routines and workouts are saved with their children in one transaction through the `gym_save_routine` / `gym_save_workout` RPCs.
- Photos go to the private Storage bucket `gym-exercise-images` under `<userId>/`.

Loads are stored as numbers: pounds for weight exercises (shown in lb or kg), a disc count for cable/machine stacks (`loadType = discs`). Disc exercises don't count toward the lb volume.

**Offline**: like Wallet, the last data loaded is cached on the device (`<app documents>/gym_tracker/users/<userId>/cache_*.json`, plus downloaded photos) and shown read-only with an offline banner. Saving needs a connection. Signing out deletes the cache.

**Upgrading from the device-only version**: on first sign-in, data saved by the earlier version (`exercises.json`, `routines.json`, `weekly_plan.json`, `workouts.json`, `images/`) is uploaded once and the files are renamed to `*.migrated.json` as a backup. A failed upload (e.g. offline) is retried on the next launch.

## Documentation

- [Run on an emulator or device](docs/getting-started.md)
- [Fill `.env.json`](docs/environment.md)
- [Bump app version and Flutter SDK](docs/versioning.md)

## Agents

See [AGENTS.md](../AGENTS.md) (Claude: [CLAUDE.md](../CLAUDE.md)).
