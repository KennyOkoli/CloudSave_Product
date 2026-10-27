import { config } from "./config.js";
import { createApp } from "./app.js";
import { ensureBucket } from "./s3.js";
import { initDb } from "./db.js";
import { startPendingCleanup } from "./jobs/cleanup-pending.js";

try {
  await initDb();
} catch (err) {
  console.error(`Can't reach MySQL at ${config.db.host}:${config.db.port}.`);
  console.error(err);
  process.exit(1);
}

try {
  await ensureBucket();
} catch (err) {
  console.error(
    `Can't reach S3 at ${config.s3.endpoint ?? "AWS"}. Is it running? (docker compose up -d)`,
  );
  console.error(err);
  process.exit(1);
}

const cleanup = startPendingCleanup();
const server = createApp().listen(config.port, () =>
  console.log(`Server running on http://localhost:${config.port}`),
);

for (const signal of ["SIGINT", "SIGTERM"] as const) {
  process.on(signal, () => {
    clearInterval(cleanup);
    server.close(() => process.exit(0));
  });
}
