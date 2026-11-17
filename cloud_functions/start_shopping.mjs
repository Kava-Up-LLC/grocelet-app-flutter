// start_shopping — "I'm at the store".
// Runs on AppAmbit Cloud Code. HTTP trigger: /api/fn/start_shopping.
// In:  { house_id, member_id }
// Out: { ok: true, shopping_since, notified, failed } · { ok: false, shopper } · { ok: false, error }
// One shopper per house at a time; a trip older than 3 hours counts as finished.
// Everyone else in the house gets: "Ana is at the store. Add what you need."

export const rows = (res) => {
  const r = res?.results?.[0];
  if (!r) return [];
  return (r.rows ?? []).map((row) =>
    Array.isArray(row) ? Object.fromEntries(r.columns.map((c, i) => [c, row[i]])) : row,
  );
};

const input = (ctx) => ctx.req?.body ?? ctx.req ?? ctx.event ?? {};

export const message = (nickname) => `${nickname} is at the store. Add what you need.`;

export const handler = async (ctx) => {
  const { house_id: houseId, member_id: memberId } = input(ctx);
  if (!houseId || !memberId) return { ok: false, error: 'BAD_INPUT' };

  const [me] = rows(await ctx.appambit.db(
    'SELECT nickname FROM members WHERE id = ? AND house_id = ?', [memberId, houseId]));
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
    'SELECT consumer_id FROM members WHERE house_id = ? AND id <> ? AND consumer_id IS NOT NULL',
    [houseId, memberId]));

  let notified = 0;
  let failed = 0;
  for (const { consumer_id: consumerId } of others) {
    try {
      await ctx.appambit.push({
        title: 'Grocelet',
        body: message(me.nickname),
        data: { open: 'list', house_id: String(houseId) },
        consumer_id: Number(consumerId),
      });
      notified++;
    } catch (e) {
      failed++;
      ctx.log?.('push failed', String(e?.code ?? e?.message ?? e));
    }
  }
  return { ok: true, shopping_since: house.shopping_since, notified, failed };
};
