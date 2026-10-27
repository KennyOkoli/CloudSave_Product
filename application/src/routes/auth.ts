import { Router } from "express";
import bcrypt from "bcryptjs";
import { randomUUID } from "node:crypto";
import { users } from "../db.js";
import { HttpError } from "../middleware/errors.js";
import { endSession, startSession } from "../middleware/auth.js";

export const authRouter = Router();

function readCredentials(body: unknown) {
  const { username, password } = (body ?? {}) as Record<string, unknown>;
  if (typeof username !== "string" || typeof password !== "string") {
    throw new HttpError(400, "Enter a username and password");
  }
  return { username: username.trim(), password };
}

authRouter.post("/register", async (req, res) => {
  const { username, password } = readCredentials(req.body);
  if (!/^[a-zA-Z0-9_]{3,20}$/.test(username)) {
    throw new HttpError(400, "Usernames are 3–20 letters, numbers or _");
  }
  if (password.length < 8) {
    throw new HttpError(400, "Passwords need at least 8 characters");
  }
  if (await users.findByUsername(username)) {
    throw new HttpError(409, "That username is taken");
  }

  const id = randomUUID();
  await users.create(id, username, await bcrypt.hash(password, 10));
  startSession(res, id);
  res.status(201).json({ id, username });
});

authRouter.post("/login", async (req, res) => {
  const { username, password } = readCredentials(req.body);
  const user = await users.findByUsername(username);

  // Same error for "no such user" and "wrong password" so attackers can't probe which usernames exist.
  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    throw new HttpError(401, "Wrong username or password");
  }

  startSession(res, user.id);
  res.json({ id: user.id, username: user.username });
});

authRouter.post("/logout", (_req, res) => {
  endSession(res);
  res.status(204).end();
});
