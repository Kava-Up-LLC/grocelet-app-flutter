# AGENTS.md — app_shoplist (ShopList)

Guide for any coding agent (Claude Code, Codex, Cursor…) working in this repo. Read it first.
Behavioral guidelines in the parent `../CLAUDE.md` (apps_cms) apply here too: think first, keep it simple,
touch only what you must, verify.

## What this is

ShopList — the whole house's grocery list. A Flutter app (iOS + Android) on AppAmbit: Database, one Cloud Code
function, Push, Analytics and crash reports. App 02 of the "7 apps in 7 days" series.

## Source of truth

| File | Defines |
|---|---|
| **`docs/tech/shoplist/tech_shoplist.md`** | Everything: scope (5 features, nothing more), data model, the cloud function, folder structure, how state works, screens, design tokens, acceptance criteria, risks. |
| `DESIGN.md` | The look: colors, type, spacing, components, screens. |
| `prompts.md` | The 3 prompts the app is built with, in order. |

Build only what the spec describes. If something is missing or unclear, ask — don't invent features.

## Hard rules

1. **No state-management packages** (`provider`, `riverpod`, `bloc`, `get_it`, `mobx`…). Controllers extend
   `ChangeNotifier`; views use `ListenableBuilder`. **No `setState` for app data** (spec §7.2).
2. **No other packages** than the ones in spec §3 without asking.
3. All AppAmbit SDK calls live in `lib/core/appambit/`. Views never touch the SDK or SQL.
4. Time comes from the database clock, never the phone.
5. Online only: no cache, no queue, no sync-later. Network failure → "No connection" banner + Retry.
6. Screens in English. No login, no accounts.
7. Never print, paste or commit App Keys, `.env`, `google-services.json` secrets or push credentials.
8. Work on branch **`dev`**. Never commit to `main`. One commit per prompt, clear message.
9. In UI copy, comments for the video and summaries, don't say "server" — say "AppAmbit" or "the cloud".

10. **Before writing `start_shopping`, confirm how Cloud Code sends a push to specific users** (by the user id set with `AppAmbitSdk.setUserId`) and that one function reaches members on both the iOS and the Android app. Notes from Oct 2026 say push could only be sent from the dashboard. If it isn't possible, stop and report the options — don't fake it.
11. Design: match `DESIGN.md` (colors, type, spacing, components). If it doesn't exist yet, ask.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
node --test cloud_functions/*.test.mjs
flutter run -d <device>          # flutter devices
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## Reference code (read, don't copy blindly)

- `../quote_generator_app/lib/core/services/appambit_db.dart` — DB wrapper + `inlineNulls` (Android null crash, iOS `''` → NULL).
- `../quote_generator_app/lib/main.dart` — SDK start with per-platform keys from `.env`.
- `../unshrimp_app/lib/features/push/services/push_notifications.dart` and `lib/core/config/app_startup.dart` — push SDK usage.
- `../unshrimp_app/cloud_functions/README.md` — Cloud Code handler contract (`ctx.req`, `ctx.event`, `ctx.appambit.db`).

Those apps use Riverpod and go_router; **this one doesn't**. Take the SDK knowledge, not the architecture.

## After each prompt

End with a short table: **What the agent did** — one column for **AppAmbit**, one for **the ShopList app** — in plain
words, with counts (tables, functions, screens, tests). It goes on screen in the video.
