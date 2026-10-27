import { Router } from "express";
import { randomUUID } from "node:crypto";
import { config } from "../config.js";
import { files, type FileRow } from "../db.js";
import { HttpError } from "../middleware/errors.js";
import { currentUser, requireAuth } from "../middleware/auth.js";
import {
  deleteObject,
  getObjectSize,
  presignUpload,
  presignView,
} from "../s3.js";

export const filesRouter = Router();

const { maxBytes, allowedTypes } = config.uploads;
const tooBig = () =>
  new HttpError(400, `Images must be under ${maxBytes / 1024 / 1024} MB`);

async function toDto(file: FileRow) {
  return {
    id: file.id,
    name: file.original_name,
    contentType: file.content_type,
    size: file.size,
    createdAt: file.created_at,
    url: await presignView(file.key),
  };
}

async function findOwnedOr404(id: string, userId: string) {
  const file = await files.findOwned(id, userId);
  if (!file) throw new HttpError(404, "Image not found");
  return file;
}

// Step 1 of an upload: we pick the S3 key, record the owner, and hand back a signed PUT URL.
filesRouter.post("/uploads", requireAuth, async (req, res) => {
  const user = currentUser(req);
  const { contentType, size, name } = (req.body ?? {}) as Record<
    string,
    unknown
  >;

  const ext = typeof contentType === "string" && allowedTypes[contentType];
  if (!ext) throw new HttpError(400, "Only JPEG, PNG, WebP and GIF images");
  if (typeof size !== "number" || size <= 0) {
    throw new HttpError(400, "Missing file size");
  }
  if (size > maxBytes) throw tooBig();

  const id = randomUUID();
  const key = `users/${user.id}/${id}.${ext}`;
  await files.create({
    id,
    userId: user.id,
    key,
    contentType: contentType as string,
    size,
    originalName: typeof name === "string" ? name.slice(0, 200) : null,
  });

  res
    .status(201)
    .json({ id, uploadUrl: await presignUpload(key, contentType as string) });
});

// Step 2 happens in the browser (PUT to S3). Step 3: confirm the object arrived and wasn't oversized.
filesRouter.post("/uploads/:id/complete", requireAuth, async (req, res) => {
  const file = await findOwnedOr404(req.params.id as string, currentUser(req).id);
  if (file.status === "ready") return res.json(await toDto(file));

  const size = await getObjectSize(file.key);
  if (size === null) {
    throw new HttpError(400, "The file never reached storage, try again");
  }
  if (size > maxBytes) {
    await deleteObject(file.key);
    await files.remove(file.id);
    throw tooBig();
  }

  await files.markReady(file.id, size);
  res.json(await toDto({ ...file, size, status: "ready" }));
});

filesRouter.get("/files", requireAuth, async (req, res) => {
  const rows = await files.listReady(currentUser(req).id);
  res.json(await Promise.all(rows.map(toDto)));
});

filesRouter.delete("/files/:id", requireAuth, async (req, res) => {
  const file = await findOwnedOr404(req.params.id as string, currentUser(req).id);
  await deleteObject(file.key);
  await files.remove(file.id);
  res.status(204).end();
});
