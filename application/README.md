# S3 Uploads

Express + TypeScript server with MySQL, cookie auth, per-user image uploads to S3 (presigned URLs), and a plain HTML gallery with a lightbox.

## Run

```bash
cp .env.example .env   # first time only: fill in DB_* and S3_*
docker compose up -d   # optional: local S3 (RustFS) on :9000, see .env.example
npm install
npm run dev            # http://localhost:4000
```

## Project layout

```
src/
  server.ts               boot: create tables, check S3, start cleanup job, listen
  app.ts                  express app + route mounting
  config.ts               env vars + upload limits, validated at startup
  db.ts                   MySQL pool, schema and every query (users, files)
  s3.ts                   bucket setup, presigned URLs, head/delete
  middleware/auth.ts      JWT cookie sessions, requireAuth
  middleware/errors.ts    HttpError + JSON error handler
  routes/auth.ts          register / login / logout
  routes/me.ts            current user
  routes/files.ts         upload flow, list, delete
  jobs/cleanup-pending.ts removes uploads never confirmed with /complete
public/
  index.html, styles.css
  js/main.js              boot + wiring
  js/api.js, js/ui.js     fetch wrapper, small helpers
  js/auth.js              log in / create account
  js/gallery.js           image list (shared state) + grid
  js/uploads.js           upload queue, progress tray, drag and drop
  js/lightbox.js          viewer + delete
```

## How files are linked to users

S3 only stores bytes. The `files` table in MySQL stores who owns each object:
`files.user_id -> users.id`, and `files.key` is the S3 object key (`users/{userId}/{fileId}.{ext}`).

Upload flow:
1. `POST /api/uploads` – server checks type/size, picks the key, inserts a `pending` row, returns a presigned PUT URL
2. Browser `PUT`s the file straight to S3
3. `POST /api/uploads/:id/complete` – server confirms the object exists in S3 and marks the row `ready`

Rows still `pending` after an hour are deleted (with any bytes that reached S3) by `jobs/cleanup-pending.ts`.

Viewing: the bucket is private; `GET /api/files` returns only your rows, each with a 15-minute presigned GET URL.

## API

| Method | Path | |
| --- | --- | --- |
| POST | `/api/auth/register` | `{ username, password }` |
| POST | `/api/auth/login` | `{ username, password }` |
| POST | `/api/auth/logout` | |
| GET | `/api/me` | current user + image count |
| POST | `/api/uploads` | `{ contentType, size, name }` → `{ id, uploadUrl }` |
| POST | `/api/uploads/:id/complete` | |
| GET | `/api/files` | your images |
| DELETE | `/api/files/:id` | deletes the S3 object and the row |

## Using real AWS S3

Remove `S3_ENDPOINT` from `.env` and the `endpoint` line in `src/s3.ts`, then set a real bucket, region and IAM keys.
