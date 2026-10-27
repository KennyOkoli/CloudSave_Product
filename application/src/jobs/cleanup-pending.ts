import { config } from "../config.js";
import { files } from "../db.js";
import { deleteObject } from "../s3.js";

const EVERY_MS = 10 * 60 * 1000;

// Uploads whose browser never called /complete (tab closed, network died) would sit
// as "pending" rows forever. This removes them, and any bytes that did reach S3.
async function cleanupPendingUploads() {
  const stale = await files.listStalePending(config.uploads.pendingTtlMinutes);
  for (const file of stale) {
    try {
      await deleteObject(file.key);
      await files.remove(file.id);
    } catch (err) {
      console.error(`Could not clean up pending upload ${file.id}`, err);
    }
  }
  if (stale.length) console.log(`Cleaned up ${stale.length} pending upload(s)`);
}

export function startPendingCleanup() {
  const run = () => cleanupPendingUploads().catch(console.error);
  run();
  return setInterval(run, EVERY_MS);
}
