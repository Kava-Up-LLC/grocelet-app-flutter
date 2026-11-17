// start_shopping — "I'm at the store".
// Runs on AppAmbit Cloud Code. HTTP trigger: /api/fn/start_shopping. Deployed to both apps.
// In:  { house_id, member_id }
// Out: { ok: true, shopping_since, notified, failed } · { ok: false, shopper } · { ok: false, error }
// One shopper per house at a time; a trip older than 3 hours counts as finished.
// Everyone else in the house gets: "Ana is at the store. Add what you need."
//
// ctx.appambit.push only reaches phones of the AppAmbit app this function runs in, and Grocelet has one
// app per platform. So members on the shopper's platform are pushed here, and the others through the
// other app's notify_members function (the "relay"). Secrets: OTHER_APP_KEY (App Key of the other
// AppAmbit app) and RELAY_SECRET (same value in every Grocelet function).

export const rows = (res) => {
  const r = res?.results?.[0];
  if (!r) return [];
  return (r.rows ?? []).map((row) =>
    Array.isArray(row) ? Object.fromEntries(r.columns.map((c, i) => [c, row[i]])) : row,
  );
};

const input = (ctx) => ctx.req?.body ?? ctx.req ?? ctx.event ?? {};

export const message = (nickname) => `${nickname} is at the store. Add what you need.`;

const API = 'https://appambit.com/api';
const RELAY_DEVICE = 'grocelet-relay';

const postJson = async (url, body, token) => {
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw Object.assign(new Error(`HTTP ${res.status}`), { code: `relay_http_${res.status}` });
  return res.json();
};

// Asks the other platform's AppAmbit app to push its members: get a consumer token for that app
// (one fixed "relay" consumer), then call its notify_members function with it.
export const relay = async (ctx, houseId, shopperId, platform) => {
  const appKey = ctx.secrets?.OTHER_APP_KEY;
  const secret = ctx.secrets?.RELAY_SECRET;
  if (!appKey || !secret) throw Object.assign(new Error('relay not configured'), { code: 'relay_not_configured' });
  const consumer = await postJson(`${API}/consumer`, {
    app_key: appKey, app_version: '1.0.0', device_id: RELAY_DEVICE, user_id: RELAY_DEVICE,
    device_model: 'Cloud Code relay', os: 'relay', country: 'US', language: 'en',
  });
  const res = await postJson(`${API}/fn/notify_members`,
    { house_id: houseId, shopper_id: shopperId, platform, relay_secret: secret }, consumer.token);
  if (res?.ok !== true) throw Object.assign(new Error('relay refused'), { code: String(res?.error ?? 'relay_refused') });
  return { notified: Number(res.notified ?? 0), failed: Number(res.failed ?? 0) };
};

export const handler = async (ctx) => {
  const { house_id: houseId, member_id: memberId } = input(ctx);
  if (!houseId || !memberId) return { ok: false, error: 'BAD_INPUT' };

  const [me] = rows(await ctx.appambit.db(
    'SELECT nickname, platform FROM members WHERE id = ? AND house_id = ?', [memberId, houseId]));
  if (!me) return { ok: false, error: 'NOT_A_MEMBER' };

  // Claim the trip in one statement, so two people can't both be "at the store".
  const claim = await ctx.appambit.db(
    `UPDATE houses SET shopper_id = ?, shopping_since = datetime('now')
     WHERE id = ? AND (shopper_id IS NULL OR shopper_id = ? OR shopping_since < datetime('now', '-3 hours'))`,
    [memberId, houseId, memberId]);
  if ((claim?.results?.[0]?.rows_written ?? 0) === 0) {
    const [current] = rows(await ctx.appambit.db(
      `SELECT m.nickname FROM houses h JOIN members m ON m.id = h.shopper_id WHERE h.id = ?`, [houseId]));
    return { ok: false, shopper: current?.nickname ?? null };
  }

  const [house] = rows(await ctx.appambit.db('SELECT shopping_since FROM houses WHERE id = ?', [houseId]));
  const others = rows(await ctx.appambit.db(
    'SELECT consumer_id, platform FROM members WHERE house_id = ? AND id <> ? AND consumer_id IS NOT NULL',
    [houseId, memberId]));

  // Each AppAmbit push takes ~8–10 s, so every send (and the relay) runs at the same time.
  // Same platform as the shopper: this app can push them directly.
  const here = others.filter((o) => o.platform === me.platform).map(async ({ consumer_id: consumerId }) => {
    try {
      await ctx.appambit.push({
        title: 'Grocelet',
        body: message(me.nickname),
        data: { open: 'list', house_id: String(houseId) },
        consumer_id: Number(consumerId),
      });
      return { notified: 1, failed: 0 };
    } catch (e) {
      ctx.log?.('push failed', String(e?.code ?? e?.message ?? e));
      return { notified: 0, failed: 1 };
    }
  });
  // Other platform: only its own AppAmbit app can push them.
  const away = others.filter((o) => o.platform !== me.platform);
  const there = away.length === 0 ? [] : [
    relay(ctx, houseId, memberId, me.platform === 'ios' ? 'android' : 'ios').catch((e) => {
      ctx.log?.('relay failed', String(e?.code ?? e?.message ?? e));
      return { notified: 0, failed: away.length };
    }),
  ];
  const results = await Promise.all([...here, ...there]);
  const notified = results.reduce((n, r) => n + r.notified, 0);
  const failed = results.reduce((n, r) => n + r.failed, 0);
  return { ok: true, shopping_since: house.shopping_since, notified, failed };
};
