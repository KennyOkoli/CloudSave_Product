import type { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { config } from "../config.js";
import { users, type User } from "../db.js";
import { HttpError } from "./errors.js";

const COOKIE = "token";
const SESSION_DAYS = 7;

declare global {
  namespace Express {
    interface Request {
      user?: User;
    }
  }
}

// The token lives in an httpOnly cookie, so page JavaScript can't read it (protects against XSS theft).
export function startSession(res: Response, userId: string) {
  const token = jwt.sign({ sub: userId }, config.jwtSecret, {
    expiresIn: `${SESSION_DAYS}d`,
  });
  res.cookie(COOKIE, token, {
    httpOnly: true,
    sameSite: "lax",
    secure: config.isProd,
    maxAge: SESSION_DAYS * 24 * 60 * 60 * 1000,
  });
}

export function endSession(res: Response) {
  res.clearCookie(COOKIE);
}

export async function requireAuth(
  req: Request,
  _res: Response,
  next: NextFunction,
) {
  const token = req.cookies?.[COOKIE];
  if (!token) throw new HttpError(401, "Not logged in");

  let userId: string;
  try {
    userId = (jwt.verify(token, config.jwtSecret) as { sub: string }).sub;
  } catch {
    throw new HttpError(401, "Session expired, log in again");
  }

  // A valid token for a deleted user is still a dead session.
  const user = await users.findById(userId);
  if (!user) throw new HttpError(401, "Session expired, log in again");

  req.user = user;
  next();
}

// Routes after requireAuth can call this instead of writing req.user! everywhere.
export function currentUser(req: Request) {
  if (!req.user) throw new Error("currentUser() used without requireAuth");
  return req.user;
}
