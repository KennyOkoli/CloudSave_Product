import express from "express";
import cookieParser from "cookie-parser";
import { authRouter } from "./routes/auth.js";
import { meRouter } from "./routes/me.js";
import { filesRouter } from "./routes/files.js";
import { errorHandler, notFound } from "./middleware/errors.js";

export function createApp() {
  const app = express();
  app.use(express.json());
  app.use(cookieParser());
  app.use(express.static("public"));

  app.use("/api/auth", authRouter);
  app.use("/api/me", meRouter);
  app.use("/api", filesRouter);
  app.use("/api", notFound);

  app.use(errorHandler);
  return app;
}
