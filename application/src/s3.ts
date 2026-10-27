import {
  S3Client,
  CreateBucketCommand,
  HeadBucketCommand,
  HeadObjectCommand,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  PutBucketCorsCommand,
  NotFound,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { config } from "./config.js";

const { bucket } = config.s3;

const s3 = new S3Client({
  endpoint: config.s3.endpoint,
  // Region comes from AWS_REGION (set automatically on ECS).
  // Local S3 servers need http://host/bucket/key instead of http://bucket.host/key.
  forcePathStyle: Boolean(config.s3.endpoint),
  // Without keys the SDK falls back to the environment's own AWS credentials (e.g. an IAM role).
  credentials:
    config.s3.accessKeyId && config.s3.secretAccessKey
      ? {
          accessKeyId: config.s3.accessKeyId,
          secretAccessKey: config.s3.secretAccessKey,
        }
      : undefined,
});

export async function ensureBucket() {
  try {
    await s3.send(new HeadBucketCommand({ Bucket: bucket }));
  } catch (err) {
    // A real AWS bucket is created outside the app; only a local S3 gets one made here.
    if (!config.s3.endpoint) throw err;
    await s3.send(new CreateBucketCommand({ Bucket: bucket }));
    console.log(`Created bucket "${bucket}"`);
  }

  // A real AWS bucket's CORS rule is managed in terraform; only a local S3 gets one set here.
  if (config.s3.endpoint) await setLocalBucketCors();
}

function setLocalBucketCors() {
  return s3.send(
    new PutBucketCorsCommand({
      Bucket: bucket,
      CORSConfiguration: {
        CORSRules: [
          {
            AllowedOrigins: [`http://localhost:${config.port}`],
            AllowedMethods: ["PUT", "GET"],
            AllowedHeaders: ["*"],
            MaxAgeSeconds: 3600,
          },
        ],
      },
    }),
  );
}

// The browser PUTs the file straight to S3 with this URL; it never passes through our server.
// The Content-Type is part of the signature, so the browser must send exactly this type.
export function presignUpload(key: string, contentType: string) {
  return getSignedUrl(
    s3,
    new PutObjectCommand({ Bucket: bucket, Key: key, ContentType: contentType }),
    { expiresIn: config.uploads.uploadUrlTtlSeconds },
  );
}

// The bucket is private, so viewing needs a short-lived signed URL too.
export function presignView(key: string) {
  return getSignedUrl(s3, new GetObjectCommand({ Bucket: bucket, Key: key }), {
    expiresIn: config.uploads.viewUrlTtlSeconds,
  });
}

// Returns the object's size, or null if it isn't in the bucket.
export async function getObjectSize(key: string) {
  try {
    const head = await s3.send(
      new HeadObjectCommand({ Bucket: bucket, Key: key }),
    );
    return head.ContentLength ?? 0;
  } catch (err) {
    if (err instanceof NotFound) return null;
    throw err;
  }
}

// S3 deletes succeed even when the object doesn't exist, so this is safe to retry.
export async function deleteObject(key: string) {
  await s3.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
}
