// Test helper: a ctx like AppAmbit's, backed by a real in-memory SQLite with Grocelet's schema (ShopListDb).
import { DatabaseSync } from 'node:sqlite';

export const SCHEMA = `
CREATE TABLE houses (id TEXT PRIMARY KEY, code TEXT NOT NULL UNIQUE, shopper_id TEXT, shopping_since TEXT, created_at TEXT NOT NULL DEFAULT (datetime('now')));
CREATE TABLE members (id TEXT PRIMARY KEY, house_id TEXT NOT NULL REFERENCES houses(id), nickname TEXT NOT NULL, platform TEXT NOT NULL CHECK (platform IN ('ios','android')), consumer_id INTEGER, created_at TEXT NOT NULL DEFAULT (datetime('now')));
CREATE TABLE items (id TEXT PRIMARY KEY, house_id TEXT NOT NULL REFERENCES houses(id), name TEXT NOT NULL, quantity TEXT, checked INTEGER NOT NULL DEFAULT 0, added_by TEXT NOT NULL REFERENCES members(id), created_at TEXT NOT NULL DEFAULT (datetime('now')));`;

export const fakeCtx = ({ db = new DatabaseSync(':memory:'), body = {}, consumer = null, pushFails = false, secrets = {} } = {}) => {
  if (!db.__ready) { db.exec(SCHEMA); db.__ready = true; }
  const pushes = [];
  return {
    db, pushes,
    ctx: {
      req: { body }, consumer, secrets, log: () => {},
      appambit: {
        db: async (sql, params = []) => {
          const st = db.prepare(sql);
          if (/^\s*select/i.test(sql)) {
            const out = st.all(...params);
            const columns = out.length ? Object.keys(out[0]) : [];
            return { results: [{ columns, rows: out.map((r) => columns.map((c) => r[c])), rows_written: 0 }] };
          }
          const info = st.run(...params);
          return { results: [{ columns: [], rows: [], rows_written: Number(info.changes) }] };
        },
        push: async (p) => { if (pushFails) throw Object.assign(new Error('x'), { code: 'push_failed' }); pushes.push(p); return { result: { queued: true } }; },
      },
    },
  };
};
