// join_house — create a house or join one with its 6-letter code.
// Runs on AppAmbit Cloud Code. HTTP trigger: /api/fn/join_house.
// In:  { action: "create" | "join", code?, nickname, member_id, platform: "ios" | "android" }
// Out: { ok: true, house_id, code } or { ok: false, error }
// It also saves the phone's AppAmbit consumer id, so start_shopping can send it a push.
import { randomInt, randomUUID } from 'node:crypto';

const LETTERS = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I or O: easy to read out loud
const PLATFORMS = ['ios', 'android'];

export const newCode = (pick = (n) => randomInt(n)) =>
  Array.from({ length: 6 }, () => LETTERS[pick(LETTERS.length)]).join('');

export const rows = (res) => {
  const r = res?.results?.[0];
  if (!r) return [];
  return (r.rows ?? []).map((row) =>
    Array.isArray(row) ? Object.fromEntries(r.columns.map((c, i) => [c, row[i]])) : row,
  );
};

const input = (ctx) => ctx.req?.body ?? ctx.req ?? ctx.event ?? {};

export const validate = (body) => {
  const nickname = String(body.nickname ?? '').trim();
  const memberId = String(body.member_id ?? '').trim();
  const platform = String(body.platform ?? '');
  const action = body.action;
  if (action !== 'create' && action !== 'join') return { error: 'BAD_ACTION' };
  if (nickname.length < 1 || nickname.length > 20) return { error: 'BAD_NICKNAME' };
  if (memberId.length < 8) return { error: 'BAD_MEMBER' };
  if (!PLATFORMS.includes(platform)) return { error: 'BAD_PLATFORM' };
  const code = String(body.code ?? '').trim().toUpperCase();
  if (action === 'join' && !/^[A-Z]{6}$/.test(code)) return { error: 'HOUSE_NOT_FOUND' };
  return { action, nickname, memberId, platform, code };
};

const saveMember = (ctx, houseId, v) =>
  ctx.appambit.db(
    `INSERT INTO members (id, house_id, nickname, platform, consumer_id) VALUES (?, ?, ?, ?, ?)
     ON CONFLICT(id) DO UPDATE SET house_id = excluded.house_id, nickname = excluded.nickname,
       platform = excluded.platform, consumer_id = excluded.consumer_id`,
    [v.memberId, houseId, v.nickname, v.platform, ctx.consumer?.id ?? null],
  );

export const handler = async (ctx) => {
  const v = validate(input(ctx));
  if (v.error) return { ok: false, error: v.error };

  if (v.action === 'join') {
    const [house] = rows(await ctx.appambit.db('SELECT id, code FROM houses WHERE code = ?', [v.code]));
    if (!house) return { ok: false, error: 'HOUSE_NOT_FOUND' };
    await saveMember(ctx, house.id, v);
    return { ok: true, house_id: house.id, code: house.code };
  }

  // create: a new code, retried on the rare collision with an existing one
  const houseId = randomUUID();
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = newCode();
    const res = await ctx.appambit.db(
      'INSERT INTO houses (id, code) SELECT ?, ? WHERE NOT EXISTS (SELECT 1 FROM houses WHERE code = ?)',
      [houseId, code, code],
    );
    if ((res?.results?.[0]?.rows_written ?? 0) > 0) {
      await saveMember(ctx, houseId, v);
      return { ok: true, house_id: houseId, code };
    }
  }
  return { ok: false, error: 'TRY_AGAIN' };
};
