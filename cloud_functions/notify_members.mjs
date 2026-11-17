// notify_members — send "Ana is at the store" to the house's members on ONE platform.
// Runs on AppAmbit Cloud Code. HTTP trigger: /api/fn/notify_members. Deployed to both apps.
// Why it exists: ctx.appambit.push only reaches phones of the AppAmbit app the function runs in, and
// Grocelet has one app per platform. So start_shopping (running in the shopper's app) pushes its own
// platform and calls THIS function in the other app for the rest (log: "push_no_recipients").
// In:  { house_id, shopper_id, platform: "ios" | "android", relay_secret }
// Out: { ok: true, notified, failed } · { ok: false, error }
// Phones never call it: it needs relay_secret, which only lives in the functions' secrets.

export const rows = (res) => {
  const r = res?.results?.[0];
  if (!r) return [];
  return (r.rows ?? []).map((row) =>
    Array.isArray(row) ? Object.fromEntries(r.columns.map((c, i) => [c, row[i]])) : row,
  );
};

const input = (ctx) => ctx.req?.body ?? ctx.req ?? ctx.event ?? {};

export const message = (nickname) => `${nickname} is at the store. Add what you need.`;

// Pushes every member of the house on `platform` except the shopper. Same loop as in start_shopping.
export const pushPlatform = async (ctx, houseId, shopperId, platform) => {
  const [me] = rows(await ctx.appambit.db(
    'SELECT nickname FROM members WHERE id = ? AND house_id = ?', [shopperId, houseId]));
  if (!me) return { ok: false, error: 'NOT_A_MEMBER' };
  const others = rows(await ctx.appambit.db(
    `SELECT consumer_id FROM members
     WHERE house_id = ? AND id <> ? AND platform = ? AND consumer_id IS NOT NULL`,
    [houseId, shopperId, platform]));
  // Each AppAmbit push takes ~8–10 s, so all of them run at the same time.
  const sent = await Promise.all(others.map(async ({ consumer_id: consumerId }) => {
    try {
      await ctx.appambit.push({
        title: 'Grocelet',
        body: message(me.nickname),
        data: { open: 'list', house_id: String(houseId) },
        consumer_id: Number(consumerId),
      });
      return true;
    } catch (e) {
      ctx.log?.('push failed', String(e?.code ?? e?.message ?? e));
      return false;
    }
  }));
  const notified = sent.filter(Boolean).length;
  return { ok: true, notified, failed: sent.length - notified };
};

export const handler = async (ctx) => {
  const { house_id: houseId, shopper_id: shopperId, platform, relay_secret: secret } = input(ctx);
  const expected = ctx.secrets?.RELAY_SECRET;
  if (!expected || secret !== expected) return { ok: false, error: 'FORBIDDEN' };
  if (!houseId || !shopperId || !['ios', 'android'].includes(platform)) return { ok: false, error: 'BAD_INPUT' };
  return pushPlatform(ctx, houseId, shopperId, platform);
};
