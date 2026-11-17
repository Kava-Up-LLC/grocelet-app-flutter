import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { handler as joinHouse, newCode, validate } from './join_house.mjs';
import { handler as startShopping, message } from './start_shopping.mjs';
import { handler as notifyMembers } from './notify_members.mjs';
import { fakeCtx } from './fake_ctx.mjs';

const member = (id, nickname, platform = 'ios') => ({ member_id: id, nickname, platform });

async function houseWith(...people) {
  const db = new DatabaseSync(':memory:');
  const [first, ...rest] = people;
  const { ctx } = fakeCtx({ db, body: { action: 'create', ...member(first[0], first[1], first[2]) }, consumer: { id: first[3] } });
  const created = await joinHouse(ctx);
  for (const p of rest) {
    const j = fakeCtx({ db, body: { action: 'join', code: created.code.toLowerCase(), ...member(p[0], p[1], p[2]) }, consumer: p[3] ? { id: p[3] } : null });
    assert.equal((await joinHouse(j.ctx)).ok, true);
  }
  return { db, house: created };
}

test('codes are 6 letters without I or O', () => {
  for (let i = 0; i < 200; i++) assert.match(newCode(), /^[A-HJ-NP-Z]{6}$/);
});

test('validate rejects bad input', () => {
  assert.equal(validate({ action: 'x' }).error, 'BAD_ACTION');
  assert.equal(validate({ action: 'create', nickname: ' ', member_id: 'abcdefgh', platform: 'ios' }).error, 'BAD_NICKNAME');
  assert.equal(validate({ action: 'create', nickname: 'Ana', member_id: 'abcdefgh', platform: 'web' }).error, 'BAD_PLATFORM');
  assert.equal(validate({ action: 'join', code: 'AB', nickname: 'Ana', member_id: 'abcdefgh', platform: 'ios' }).error, 'HOUSE_NOT_FOUND');
});

test('create makes a house and saves the consumer id', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11]);
  assert.equal(house.ok, true);
  assert.match(house.code, /^[A-Z]{6}$/);
  assert.deepEqual({ ...db.prepare('SELECT nickname, consumer_id, house_id FROM members').get() },
    { nickname: 'Ana', consumer_id: 11, house_id: house.house_id });
});

test('join with a wrong code fails, with the right code (any case) works', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11]);
  const bad = fakeCtx({ db, body: { action: 'join', code: 'ZZZZZZ', ...member('m-leo-0002', 'Leo', 'android') } });
  assert.deepEqual(await joinHouse(bad.ctx), { ok: false, error: 'HOUSE_NOT_FOUND' });
  const good = fakeCtx({ db, body: { action: 'join', code: ` ${house.code.toLowerCase()} `, ...member('m-leo-0002', 'Leo', 'android') }, consumer: { id: 22 } });
  assert.deepEqual(await joinHouse(good.ctx), { ok: true, house_id: house.house_id, code: house.code });
});

test('joining again refreshes the consumer id instead of duplicating the member', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11]);
  const again = fakeCtx({ db, body: { action: 'join', code: house.code, ...member('m-ana-0001', 'Ana', 'ios') }, consumer: { id: 99 } });
  await joinHouse(again.ctx);
  assert.equal(db.prepare('SELECT count(*) n FROM members').get().n, 1);
  assert.equal(db.prepare('SELECT consumer_id c FROM members').get().c, 99);
});

const SECRETS = { OTHER_APP_KEY: 'other-app-key', RELAY_SECRET: 'relay-secret' };

// Stands in for the OTHER AppAmbit app: /api/consumer returns a token, /api/fn/notify_members runs the
// real notify_members on the same database and records its pushes in `otherPushes`.
function fakeOtherApp(db, { notifyResult } = {}) {
  const calls = [];
  const otherPushes = [];
  const fetch = async (url, init) => {
    const body = JSON.parse(init.body);
    calls.push({ url, body, auth: init.headers.Authorization ?? null });
    const json = (data, status = 200) => ({ ok: status < 400, status, json: async () => data });
    if (url.endsWith('/api/consumer')) return json({ id: 1, token: 'relay-token' });
    if (url.endsWith('/api/fn/notify_members')) {
      if (notifyResult) return json(notifyResult);
      const f = fakeCtx({ db, body, secrets: { RELAY_SECRET: 'relay-secret' } });
      const res = await notifyMembers(f.ctx);
      otherPushes.push(...f.pushes);
      return json(res);
    }
    return json({}, 404);
  };
  return { fetch, calls, otherPushes };
}

async function withFetch(fake, fn) {
  const saved = globalThis.fetch;
  globalThis.fetch = fake;
  try { return await fn(); } finally { globalThis.fetch = saved; }
}

test('start_shopping pushes its own platform and relays the other one, never the shopper', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11], ['m-leo-0002', 'Leo', 'android', 22], ['m-sam-0003', 'Sam', 'ios', 33]);
  const other = fakeOtherApp(db);
  const f = fakeCtx({ db, body: { house_id: house.house_id, member_id: 'm-ana-0001' }, secrets: SECRETS });
  const res = await withFetch(other.fetch, () => startShopping(f.ctx));
  assert.equal(res.ok, true);
  assert.equal(res.notified, 2);
  assert.equal(res.failed, 0);
  assert.deepEqual(f.pushes.map((p) => p.consumer_id), [33]); // iOS app pushes Sam (iOS)
  assert.deepEqual(other.otherPushes.map((p) => p.consumer_id), [22]); // Android app pushes Leo
  for (const p of [...f.pushes, ...other.otherPushes]) {
    assert.equal(p.body, 'Ana is at the store. Add what you need.');
    assert.deepEqual(p.data, { open: 'list', house_id: house.house_id });
  }
  assert.equal(other.calls[0].body.app_key, 'other-app-key');
  assert.ok(other.calls[0].body.app_version); // /api/consumer answers 422 without it
  assert.equal(other.calls[1].auth, 'Bearer relay-token');
  assert.deepEqual(other.calls[1].body,
    { house_id: house.house_id, shopper_id: 'm-ana-0001', platform: 'android', relay_secret: 'relay-secret' });
  assert.ok(res.shopping_since);
});

test('no relay call when everyone is on the shopper\'s platform', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11], ['m-sam-0003', 'Sam', 'ios', 33]);
  const other = fakeOtherApp(db);
  const res = await withFetch(other.fetch, () =>
    startShopping(fakeCtx({ db, body: { house_id: house.house_id, member_id: 'm-ana-0001' } }).ctx));
  assert.deepEqual({ notified: res.notified, failed: res.failed }, { notified: 1, failed: 0 });
  assert.equal(other.calls.length, 0);
});

test('a relay that is not configured or refused counts as failed, the trip still starts', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11], ['m-leo-0002', 'Leo', 'android', 22]);
  const noSecrets = await withFetch(fakeOtherApp(db).fetch, () =>
    startShopping(fakeCtx({ db, body: { house_id: house.house_id, member_id: 'm-ana-0001' } }).ctx));
  assert.deepEqual({ ok: noSecrets.ok, notified: noSecrets.notified, failed: noSecrets.failed }, { ok: true, notified: 0, failed: 1 });
  const refused = await withFetch(fakeOtherApp(db, { notifyResult: { ok: false, error: 'FORBIDDEN' } }).fetch, () =>
    startShopping(fakeCtx({ db, body: { house_id: house.house_id, member_id: 'm-ana-0001' }, secrets: SECRETS }).ctx));
  assert.deepEqual({ ok: refused.ok, notified: refused.notified, failed: refused.failed }, { ok: true, notified: 0, failed: 1 });
});

test('notify_members needs the relay secret and pushes only its platform', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11], ['m-leo-0002', 'Leo', 'android', 22], ['m-sam-0003', 'Sam', 'ios', 33]);
  const body = { house_id: house.house_id, shopper_id: 'm-ana-0001', platform: 'android', relay_secret: 'wrong' };
  const bad = fakeCtx({ db, body, secrets: { RELAY_SECRET: 'relay-secret' } });
  assert.deepEqual(await notifyMembers(bad.ctx), { ok: false, error: 'FORBIDDEN' });
  assert.equal(bad.pushes.length, 0);
  const unset = fakeCtx({ db, body: { ...body, relay_secret: undefined } });
  assert.deepEqual(await notifyMembers(unset.ctx), { ok: false, error: 'FORBIDDEN' });
  const good = fakeCtx({ db, body: { ...body, relay_secret: 'relay-secret' }, secrets: { RELAY_SECRET: 'relay-secret' } });
  assert.deepEqual(await notifyMembers(good.ctx), { ok: true, notified: 1, failed: 0 });
  assert.deepEqual(good.pushes.map((p) => p.consumer_id), [22]);
  const stranger = fakeCtx({ db, body: { ...body, shopper_id: 'm-zed-0009', relay_secret: 'relay-secret' }, secrets: { RELAY_SECRET: 'relay-secret' } });
  assert.deepEqual(await notifyMembers(stranger.ctx), { ok: false, error: 'NOT_A_MEMBER' });
});

test('a second shopper is refused while the first is at the store', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11], ['m-leo-0002', 'Leo', 'android', 22]);
  await startShopping(fakeCtx({ db, body: { house_id: house.house_id, member_id: 'm-ana-0001' } }).ctx);
  const f = fakeCtx({ db, body: { house_id: house.house_id, member_id: 'm-leo-0002' } });
  assert.deepEqual(await startShopping(f.ctx), { ok: false, shopper: 'Ana' });
  assert.equal(f.pushes.length, 0);
});

test('a trip older than 3 hours can be taken over', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11], ['m-leo-0002', 'Leo', 'android', 22]);
  db.prepare("UPDATE houses SET shopper_id = 'm-ana-0001', shopping_since = datetime('now', '-4 hours')").run();
  const res = await startShopping(fakeCtx({ db, body: { house_id: house.house_id, member_id: 'm-leo-0002' } }).ctx);
  assert.equal(res.ok, true);
  assert.equal(db.prepare('SELECT shopper_id s FROM houses').get().s, 'm-leo-0002');
});

test('members without a consumer id are skipped; a failed push does not break the trip', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11], ['m-leo-0002', 'Leo', 'ios', null]);
  const res = await startShopping(fakeCtx({ db, body: { house_id: house.house_id, member_id: 'm-ana-0001' }, pushFails: true }).ctx);
  assert.deepEqual({ ok: res.ok, notified: res.notified, failed: res.failed }, { ok: true, notified: 0, failed: 0 });
  const { db: db2, house: h2 } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11], ['m-leo-0002', 'Leo', 'ios', 22]);
  const r2 = await startShopping(fakeCtx({ db: db2, body: { house_id: h2.house_id, member_id: 'm-ana-0001' }, pushFails: true }).ctx);
  assert.deepEqual({ ok: r2.ok, notified: r2.notified, failed: r2.failed }, { ok: true, notified: 0, failed: 1 });
});

test('someone outside the house cannot start a trip', async () => {
  const { db, house } = await houseWith(['m-ana-0001', 'Ana', 'ios', 11]);
  const res = await startShopping(fakeCtx({ db, body: { house_id: house.house_id, member_id: 'm-zed-0009' } }).ctx);
  assert.deepEqual(res, { ok: false, error: 'NOT_A_MEMBER' });
  assert.equal(message('Ana'), 'Ana is at the store. Add what you need.');
});
