# Cloud Code — Grocelet

Three functions on AppAmbit Cloud Code, deployed to **both** apps ("App ShopList - ios" and "App ShopList - Android" in AppAmbit) with an HTTP
trigger of the same name. Both apps share the database **ShopListDb**.

| Function | In | Out |
|---|---|---|
| `join_house` | `{ action: "create" \| "join", code?, nickname, member_id, platform }` | `{ ok, house_id, code }` · `{ ok: false, error: "HOUSE_NOT_FOUND" \| "BAD_*" \| "TRY_AGAIN" }` |
| `start_shopping` | `{ house_id, member_id }` | `{ ok: true, shopping_since, notified, failed }` · `{ ok: false, shopper }` · `{ ok: false, error }` |
| `notify_members` | `{ house_id, shopper_id, platform, relay_secret }` | `{ ok: true, notified, failed }` · `{ ok: false, error: "FORBIDDEN" \| "BAD_INPUT" \| "NOT_A_MEMBER" }` |

- `join_house` saves the caller's AppAmbit consumer id (`ctx.consumer.id`) on the member. The app calls it again
  (action `join`) on every start, so the id stays current.
- `start_shopping` claims the trip in one `UPDATE` (one shopper per house; a trip older than 3 hours can be taken
  over) and notifies every other member by `consumer_id`.
- **One app per platform → a relay.** `ctx.appambit.push` only reaches phones of the AppAmbit app the function runs in
  (a push to the other app's consumer fails with `push_no_recipients`). So `start_shopping` pushes the members on the
  shopper's platform itself, and for the others it gets a consumer token for the other app (`POST /api/consumer`
  with that app's key, fixed device `grocelet-relay`) and calls that app's `notify_members`, which pushes them.
  Sends run in parallel.
- Secrets (set in the dashboard, Env & Secrets, "Is secret"): `start_shopping` needs `OTHER_APP_KEY` (App Key of the
  *other* app) and `RELAY_SECRET`; `notify_members` needs `RELAY_SECRET` (same value everywhere). Phones never know
  it, so they can't call `notify_members`.
- Timeout 30 000 ms on `start_shopping` and `notify_members`: a push can take ~8–10 s on a cold start.
- Checked 2026-11-17: Event and Schedule triggers never fired in this AppAmbit team, so the relay uses HTTP only.
  AppAmbit can keep a Cloud Code push "Scheduled" for up to ~2 min before "Sent".
- Single files, Node built-ins only (`node:crypto`). Rows from `ctx.appambit.db` come back positional with
  `columns`; `rows()` maps them to objects.

Tests run against a real in-memory SQLite with the same schema:

```bash
node --test cloud_functions/*.test.mjs
```
