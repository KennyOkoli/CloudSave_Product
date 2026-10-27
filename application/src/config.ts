function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing env var ${name} (see .env.example)`);
  return value;
}

export const config = {
  port: Number(process.env.PORT ?? 4000),
  appOrigin: process.env.APP_ORIGIN ?? "http://localhost:4000",
  isProd: process.env.NODE_ENV === "production",
  jwtSecret: required("JWT_SECRET"),

  db: {
    host: required("DB_HOST"),
    port: Number(process.env.DB_PORT ?? 3306),
    name: required("DB_NAME"),
    user: required("DB_USER"),
    password: required("DB_PASSWORD"),
  },

  s3: {
    // Leave S3_ENDPOINT unset to talk to real AWS S3.
    endpoint: process.env.S3_ENDPOINT || undefined,
    region: required("S3_REGION"),
    bucket: required("S3_BUCKET"),
    // Leave both unset on AWS to use the server's IAM role instead of keys.
    accessKeyId: process.env.S3_ACCESS_KEY || undefined,
    secretAccessKey: process.env.S3_SECRET_KEY || undefined,
  },

  uploads: {
    maxBytes: 10 * 1024 * 1024,
    // content type -> file extension used in the S3 key
    allowedTypes: {
      "image/jpeg": "jpg",
      "image/png": "png",
      "image/webp": "webp",
      "image/gif": "gif",
    } as Record<string, string>,
    uploadUrlTtlSeconds: 5 * 60,
    viewUrlTtlSeconds: 15 * 60,
    // Uploads never confirmed with /complete are removed after this long.
    pendingTtlMinutes: 60,
  },
};
