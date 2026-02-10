import 'dotenv/config';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import {
  CreateBucketCommand,
  HeadBucketCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';

const ALLOWED_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp']);
const MAX_FILE_SIZE_BYTES = 2 * 1024 * 1024;

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is missing.`);
  }
  return value;
}

function requiredAreaArg(argv: string[]): string {
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === '--area') {
      const value = argv[index + 1]?.trim();
      if (value) {
        return value;
      }
      break;
    }

    if (token.startsWith('--area=')) {
      const value = token.slice('--area='.length).trim();
      if (value) {
        return value;
      }
      break;
    }
  }

  throw new Error(
    'Missing required argument --area. Example: npm run media:upload -- --area \"一食堂 1F\"',
  );
}

function buildPrismaClient(): PrismaClient {
  const connectionString = requiredEnv('DATABASE_URL');
  return new PrismaClient({
    adapter: new PrismaPg(
      new Pool({
        connectionString,
      }),
    ),
  });
}

function buildS3Client(): S3Client {
  const endpoint = requiredEnv('MEDIA_ENDPOINT');
  const accessKeyId = requiredEnv('MINIO_ROOT_USER');
  const secretAccessKey = requiredEnv('MINIO_ROOT_PASSWORD');

  return new S3Client({
    endpoint,
    region: 'us-east-1',
    forcePathStyle: true,
    credentials: {
      accessKeyId,
      secretAccessKey,
    },
  });
}

function parseFileName(fileName: string): {
  storeName: string;
  dishName: string;
  extension: string;
} | null {
  const extension = path.extname(fileName).toLowerCase();
  if (!ALLOWED_EXTENSIONS.has(extension)) {
    return null;
  }

  const stem = path.basename(fileName, extension);
  const parts = stem.split('__');
  if (parts.length !== 2) {
    return null;
  }

  const storeName = parts[0].trim();
  const dishName = parts[1].trim();
  if (!storeName || !dishName) {
    return null;
  }

  return {
    storeName,
    dishName,
    extension: extension === '.jpeg' ? '.jpg' : extension,
  };
}

function contentTypeForExtension(extension: string): string {
  switch (extension) {
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.jpg':
    default:
      return 'image/jpeg';
  }
}

async function ensureBucketExists(client: S3Client, bucket: string): Promise<void> {
  try {
    await client.send(new HeadBucketCommand({ Bucket: bucket }));
  } catch {
    await client.send(new CreateBucketCommand({ Bucket: bucket }));
  }
}

async function main(): Promise<void> {
  const prisma = buildPrismaClient();
  const s3 = buildS3Client();

  const bucket = requiredEnv('MEDIA_BUCKET');
  const campusCode = process.env.CAMPUS_CODE?.trim() || 'nuist';
  const imagesDir = process.env.DISH_IMAGES_DIR?.trim() || path.resolve(process.cwd(), 'assets/dishes');
  const targetArea = requiredAreaArg(process.argv.slice(2));

  await ensureBucketExists(s3, bucket);

  const entries = await fs.readdir(imagesDir, { withFileTypes: true });
  const files = entries.filter((entry) => entry.isFile()).map((entry) => entry.name);

  if (files.length === 0) {
    console.log(`No files found in ${imagesDir}`);
    await prisma.$disconnect();
    return;
  }

  let uploaded = 0;
  let skipped = 0;

  try {
    for (const fileName of files) {
      const mapping = parseFileName(fileName);
      if (!mapping) {
        skipped += 1;
        console.warn(`Skip invalid filename: ${fileName}`);
        continue;
      }

      const fullPath = path.join(imagesDir, fileName);
      const stats = await fs.stat(fullPath);
      if (stats.size > MAX_FILE_SIZE_BYTES) {
        skipped += 1;
        console.warn(`Skip oversized file (>2MB): ${fileName}`);
        continue;
      }

      const matchedStores = await prisma.campusStore.findMany({
        where: {
          campusCode,
          name: mapping.storeName,
        },
        select: {
          id: true,
          area: true,
        },
      });

      const exactStores = matchedStores.filter((store) => store.area === targetArea);

      if (exactStores.length === 0) {
        skipped += 1;
        if (matchedStores.length === 0) {
          console.error(`Store not found: ${mapping.storeName} (campus=${campusCode}, area=${targetArea})`);
        } else {
          const candidates = matchedStores.map((item) => `${item.id}:${item.area}`).join(', ');
          console.error(
            `Store area mismatch: ${mapping.storeName} (requested area=${targetArea}). Candidates => ${candidates}`,
          );
        }
        continue;
      }

      if (exactStores.length > 1) {
        skipped += 1;
        const candidates = exactStores.map((item) => `${item.id}:${item.area}`).join(', ');
        console.error(`Store match is ambiguous: ${mapping.storeName} / ${targetArea}. Candidates => ${candidates}`);
        continue;
      }

      const store = exactStores[0];

      const dish = await prisma.storeDish.findFirst({
        where: {
          storeId: store.id,
          name: mapping.dishName,
        },
        select: {
          id: true,
        },
      });

      if (!dish) {
        skipped += 1;
        console.warn(`Dish not found: ${mapping.storeName} / ${mapping.dishName}`);
        continue;
      }

      const key = `${campusCode}/${store.id}/${dish.id}${mapping.extension}`;
      const body = await fs.readFile(fullPath);

      await s3.send(
        new PutObjectCommand({
          Bucket: bucket,
          Key: key,
          Body: body,
          ContentType: contentTypeForExtension(mapping.extension),
          CacheControl: 'public, max-age=604800, immutable',
        }),
      );

      await prisma.storeDish.update({
        where: { id: dish.id },
        data: { imageKey: key },
      });

      uploaded += 1;
      console.log(`Uploaded: ${fileName} -> ${key}`);
    }

    console.log(`Done. Uploaded=${uploaded}, Skipped=${skipped}, Total=${files.length}`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
