import mysql, { type RowDataPacket } from "mysql2/promise";
import { config } from "./config.js";

// A pool keeps a few open connections and reuses them, instead of reconnecting per query.
export const db = mysql.createPool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.name,
  user: config.db.user,
  password: config.db.password,
  connectionLimit: 10,
  // Return DATETIME columns as "YYYY-MM-DD HH:MM:SS" strings, the format the UI parses.
  dateStrings: true,
});

// Times are stored in UTC (UTC_TIMESTAMP), whatever timezone the DB server runs in.
export async function initDb() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS users (
      id            CHAR(36) PRIMARY KEY,
      username      VARCHAR(20) NOT NULL UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      created_at    DATETIME(3) NOT NULL
    )
  `);

  // This table is the link between a user and their S3 objects.
  // S3 only holds the bytes; "who owns what" lives here.
  await db.query(`
    CREATE TABLE IF NOT EXISTS files (
      id            CHAR(36) PRIMARY KEY,
      user_id       CHAR(36) NOT NULL,
      \`key\`         VARCHAR(255) NOT NULL UNIQUE,
      content_type  VARCHAR(100) NOT NULL,
      size          INT NOT NULL,
      original_name VARCHAR(200),
      status        ENUM('pending', 'ready') NOT NULL DEFAULT 'pending',
      created_at    DATETIME(3) NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);
}

export type User = {
  id: string;
  username: string;
  password_hash: string;
  created_at: string;
};
export type FileRow = {
  id: string;
  user_id: string;
  key: string;
  content_type: string;
  size: number;
  original_name: string | null;
  status: "pending" | "ready";
  created_at: string;
};

// All SQL lives here so routes read as plain function calls.

async function all<T>(sql: string, params: unknown[]) {
  const [rows] = await db.query<RowDataPacket[]>(sql, params);
  return rows as T[];
}
async function one<T>(sql: string, params: unknown[]) {
  return (await all<T>(sql, params))[0] as T | undefined;
}

export const users = {
  async create(id: string, username: string, passwordHash: string) {
    await db.query(
      `INSERT INTO users (id, username, password_hash, created_at)
       VALUES (?, ?, ?, UTC_TIMESTAMP(3))`,
      [id, username, passwordHash],
    );
  },
  findById(id: string) {
    return one<User>("SELECT * FROM users WHERE id = ?", [id]);
  },
  // MySQL's default collation compares case-insensitively, so "Ada" finds "ada".
  findByUsername(username: string) {
    return one<User>("SELECT * FROM users WHERE username = ?", [username]);
  },
};

export const files = {
  async create(file: {
    id: string;
    userId: string;
    key: string;
    contentType: string;
    size: number;
    originalName: string | null;
  }) {
    await db.query(
      `INSERT INTO files (id, user_id, \`key\`, content_type, size, original_name, created_at)
       VALUES (?, ?, ?, ?, ?, ?, UTC_TIMESTAMP(3))`,
      [
        file.id,
        file.userId,
        file.key,
        file.contentType,
        file.size,
        file.originalName,
      ],
    );
  },
  // Every lookup by id also filters by owner, so users can only touch their own files.
  findOwned(id: string, userId: string) {
    return one<FileRow>("SELECT * FROM files WHERE id = ? AND user_id = ?", [
      id,
      userId,
    ]);
  },
  listReady(userId: string) {
    return all<FileRow>(
      `SELECT * FROM files WHERE user_id = ? AND status = 'ready'
       ORDER BY created_at DESC`,
      [userId],
    );
  },
  async countReady(userId: string) {
    const row = await one<{ count: number }>(
      "SELECT COUNT(*) AS count FROM files WHERE user_id = ? AND status = 'ready'",
      [userId],
    );
    return Number(row?.count ?? 0);
  },
  async markReady(id: string, size: number) {
    await db.query("UPDATE files SET status = 'ready', size = ? WHERE id = ?", [
      size,
      id,
    ]);
  },
  async remove(id: string) {
    await db.query("DELETE FROM files WHERE id = ?", [id]);
  },
  listStalePending(olderThanMinutes: number) {
    return all<FileRow>(
      `SELECT * FROM files WHERE status = 'pending'
       AND created_at < UTC_TIMESTAMP(3) - INTERVAL ? MINUTE`,
      [olderThanMinutes],
    );
  },
};
