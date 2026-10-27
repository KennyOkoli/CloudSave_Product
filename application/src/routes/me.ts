import { Router } from "express";
import { files } from "../db.js";
import { currentUser, requireAuth } from "../middleware/auth.js";

export const meRouter = Router();

meRouter.get("/", requireAuth, async (req, res) => {
  const user = currentUser(req);
  res.json({
    id: user.id,
    username: user.username,
    createdAt: user.created_at,
    imageCount: await files.countReady(user.id),
  });
});
