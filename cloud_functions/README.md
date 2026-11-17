# Cloud Code — ShopList

Two functions on AppAmbit Cloud Code, deployed to **both** apps (ShopList iOS and ShopList Android) with an HTTP
trigger of the same name. Both apps share the database **ShopListDb**.

| Function | In | Out |
|---|---|---|
| `join_house` | `{ action: "create" \| "join", code?, nickname, member_id, platform }` | `{ ok, house_id, code }` · `{ ok: false, error: "HOUSE_NOT_FOUND" \| "BAD_*" \| "TRY_AGAIN" }` |
| `start_shopping` | `{ house_id, member_id }` | `{ ok: true, shopping_since, notified, failed }` · `{ ok: false, shopper }` · `{ ok: false, error }` |

- `join_house` saves the caller's AppAmbit consumer id (`ctx.consumer.id`) on the member. The app calls it again
  (action `join`) on every start, so the id stays current.
- `start_shopping` claims the trip in one `UPDATE` (one shopper per house; a trip older than 3 hours can be taken
  over) and sends `ctx.appambit.push` to every other member by `consumer_id`.
- Single files, Node built-ins only (`node:crypto`). Rows from `ctx.appambit.db` come back positional with
  `columns`; `rows()` maps them to objects.

Tests run against a real in-memory SQLite with the same schema:

```bash
node --test cloud_functions/
```
