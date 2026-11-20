# Gym Tracker — SwiftUI (iOS 26, Liquid Glass)

Native port of the [Flutter app](../flutter). Same Supabase project, same
`gym_` tables, RPCs and offline cache layout, so both apps can be used side by
side with the same account.

Requires **Xcode 26** and the **iOS 26 simulator/SDK**.

## Quick start

```sh
cp swift/GymConfig.example.plist swift/GymTracker/Resources/GymConfig.plist   # then fill in real values
open swift/GymTracker.xcodeproj
```

The values are the same as the Flutter `.env.json` (`SUPABASE_URL`,
`SUPABASE_ANON_KEY`). Without the file the app shows a "not configured" screen.
The `gym_` migration has to be applied to that project first (supabase repo).

## Behind a corporate network

If sign-in fails with `NSURLErrorDomain -1200` / `-9802`, a corporate network
service is inspecting TLS and the simulator doesn't trust its root CA. Each
simulator has its own trust store, separate from the Mac's. Trust the CA in
the booted simulator (or pass `all`):

```sh
swift/scripts/trust_dev_proxy_cert.sh path/to/corporate_root_ca.pem
swift/scripts/trust_dev_proxy_cert.sh path/to/corporate_root_ca.pem all
```

Keep the certificate out of git (`*.pem` is ignored). The app needs no code
change.

## Layout

| Path | What |
|---|---|
| `Packages/GymCore/Sources/GymCore` | Entities, Monday-based weeks, lb/kg conversion, dashboard stats, exercise progress and workout building. No I/O. |
| `Packages/GymCore/Sources/GymData` | Supabase repository (`gym_*` tables, `gym_save_routine` / `gym_save_workout`), offline JSON cache, legacy device-data upload. |
| `Packages/GymCore/Tests` | Swift Testing suites; the Flutter `test/` cases are ported here. |
| `GymTracker/App` | App entry, session model, preferences (language, theme, Face ID, weight unit), tab shell. |
| `GymTracker/Features` | Dashboard, workouts, plan, exercises, settings. |
| `GymTracker/Components` | Labels, dates, linked lb/kg fields. |
| `GymTracker/Resources` | Assets and `Localizable.xcstrings` (English and Spanish). |

The project uses a synchronized folder, so new files under `GymTracker/` are
picked up by Xcode automatically.

## Tests

```sh
cd swift/Packages/GymCore && swift test
```

## Strings

`Localizable.xcstrings` is generated from the Flutter `.arb` files (same keys,
ICU plurals become `key#one` variants) plus `scripts/swift_only_strings.json`.
After changing either:

```sh
python3 -I swift/scripts/arb_to_xcstrings.py
```

## Design (Liquid Glass)

The Flutter bottom bar becomes a floating glass tab bar that minimizes on scroll:

- **Dashboard** — this week vs last week, 8-week volume and reps, sets and reps per muscle, strength trends, personal records.
- **Workouts** — today's plan, history, and the logging screen (check sets, edit reps and load, add exercises). Changes save automatically.
- **Plan** — assign a routine to each weekday, edit routines.
- **Exercises** — library with muscles, equipment, load type (weight or stack discs) and reference photos.

Settings (email, password, Face ID, language, theme, lb/kg) opens from the toolbar. Loads are stored in pounds; disc exercises stay a plain count and stay out of the pound volume. Glass is used on the tab bar and sign-in controls, not on list content.
