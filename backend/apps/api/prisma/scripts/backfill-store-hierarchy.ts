import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, StoreLocationType } from '@prisma/client';
import { Pool } from 'pg';
import { findStoreFloorOverride } from './store-floor-overrides';

const DEFAULT_FLOOR_ORDER = 1;
const DEFAULT_FLOOR_LABEL = '1F';

type FloorInfo = {
  floorOrder: number;
  floorLabel: string;
};

type HierarchyInfo = {
  canteenName: string;
  floor: FloorInfo;
};

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is missing.`);
  }
  return value;
}

function normalizeText(value: string): string {
  return value.trim().replace(/\s+/g, '');
}

function parseChineseNumber(raw: string): number | null {
  const map: Record<string, number> = {
    一: 1,
    二: 2,
    三: 3,
    四: 4,
    五: 5,
    六: 6,
    七: 7,
    八: 8,
    九: 9,
    十: 10,
  };

  if (!raw) {
    return null;
  }

  if (raw === '十') {
    return 10;
  }

  if (raw.startsWith('十')) {
    const suffix = map[raw.slice(1)];
    return suffix ? 10 + suffix : null;
  }

  if (raw.endsWith('十')) {
    const prefix = map[raw.slice(0, -1)];
    return prefix ? prefix * 10 : null;
  }

  if (raw.includes('十')) {
    const [prefixRaw, suffixRaw] = raw.split('十');
    const prefix = map[prefixRaw] ?? 0;
    const suffix = map[suffixRaw] ?? 0;
    const value = prefix * 10 + suffix;
    return value > 0 ? value : null;
  }

  return map[raw] ?? null;
}

function parseFloorInfo(...sources: string[]): FloorInfo | null {
  for (const source of sources) {
    const normalized = source.trim();
    if (!normalized) {
      continue;
    }

    const basementByF = normalized.match(/\bB\s*(\d+)\b/i);
    if (basementByF) {
      const value = Number.parseInt(basementByF[1], 10);
      if (Number.isFinite(value) && value > 0) {
        return {
          floorOrder: -value,
          floorLabel: `B${value}`,
        };
      }
    }

    const basementByChinese = normalized.match(/地下\s*(\d+)\s*层/);
    if (basementByChinese) {
      const value = Number.parseInt(basementByChinese[1], 10);
      if (Number.isFinite(value) && value > 0) {
        return {
          floorOrder: -value,
          floorLabel: `B${value}`,
        };
      }
    }

    const floorByF = normalized.match(/\b(\d+)\s*F\b/i);
    if (floorByF) {
      const value = Number.parseInt(floorByF[1], 10);
      if (Number.isFinite(value) && value > 0) {
        return {
          floorOrder: value,
          floorLabel: `${value}F`,
        };
      }
    }

    const floorByLevel = normalized.match(/(\d+)\s*层/);
    if (floorByLevel) {
      const value = Number.parseInt(floorByLevel[1], 10);
      if (Number.isFinite(value) && value > 0) {
        return {
          floorOrder: value,
          floorLabel: `${value}F`,
        };
      }
    }

    const floorByChineseLevel = normalized.match(/([一二三四五六七八九十]+)层/);
    if (floorByChineseLevel) {
      const value = parseChineseNumber(floorByChineseLevel[1]);
      if (value && value > 0) {
        return {
          floorOrder: value,
          floorLabel: `${value}F`,
        };
      }
    }
  }

  return null;
}

function inferCanteenName(area: string, storeName: string): string | null {
  const candidates = [area, storeName];

  for (const candidate of candidates) {
    const normalized = candidate.trim();
    if (!normalized) {
      continue;
    }

    const prefix = normalized.split(/[·\s]/)[0];
    if (prefix.includes('食堂')) {
      return prefix;
    }

    const matched = normalized.match(/([^\s·]+食堂)/);
    if (matched) {
      return matched[1];
    }
  }

  return null;
}

function resolveHierarchy(store: {
  campusCode: string;
  name: string;
  area: string;
}): HierarchyInfo | null {
  const override = findStoreFloorOverride({
    campusCode: store.campusCode,
    storeName: store.name,
    area: store.area,
  });

  if (override) {
    return {
      canteenName: override.canteenName,
      floor: {
        floorOrder: override.floorOrder,
        floorLabel: override.floorLabel,
      },
    };
  }

  const isCanteenStore = normalizeText(store.area).includes('食堂');
  if (!isCanteenStore) {
    return null;
  }

  const canteenName =
    inferCanteenName(store.area, store.name) ??
    (store.area.trim() || '未命名食堂');

  const floor = parseFloorInfo(store.area, store.name) ?? {
    floorOrder: DEFAULT_FLOOR_ORDER,
    floorLabel: DEFAULT_FLOOR_LABEL,
  };

  return { canteenName, floor };
}

async function main(): Promise<void> {
  const prisma = new PrismaClient({
    adapter: new PrismaPg(
      new Pool({
        connectionString: requiredEnv('DATABASE_URL'),
      }),
    ),
  });

  let canteenStoreCount = 0;
  let outdoorStoreCount = 0;

  try {
    const stores = await prisma.campusStore.findMany({
      select: {
        id: true,
        campusCode: true,
        name: true,
        area: true,
      },
      orderBy: [{ campusCode: 'asc' }, { area: 'asc' }, { name: 'asc' }],
    });

    for (const store of stores) {
      const hierarchy = resolveHierarchy(store);

      if (!hierarchy) {
        await prisma.campusStore.update({
          where: { id: store.id },
          data: {
            locationType: StoreLocationType.OUTDOOR,
            floorId: null,
          },
        });
        outdoorStoreCount += 1;
        continue;
      }

      const canteen = await prisma.campusCanteen.upsert({
        where: {
          campusCode_name: {
            campusCode: store.campusCode,
            name: hierarchy.canteenName,
          },
        },
        update: {
          name: hierarchy.canteenName,
        },
        create: {
          campusCode: store.campusCode,
          name: hierarchy.canteenName,
        },
      });

      const floor = await prisma.canteenFloor.upsert({
        where: {
          canteenId_floorOrder: {
            canteenId: canteen.id,
            floorOrder: hierarchy.floor.floorOrder,
          },
        },
        update: {
          floorLabel: hierarchy.floor.floorLabel,
        },
        create: {
          canteenId: canteen.id,
          floorOrder: hierarchy.floor.floorOrder,
          floorLabel: hierarchy.floor.floorLabel,
        },
      });

      await prisma.campusStore.update({
        where: { id: store.id },
        data: {
          locationType: StoreLocationType.CANTEEN,
          floorId: floor.id,
          area: `${hierarchy.canteenName} ${floor.floorLabel}`,
        },
      });

      canteenStoreCount += 1;
    }

    console.log(
      `Backfill completed. canteenStores=${canteenStoreCount}, outdoorStores=${outdoorStoreCount}, total=${stores.length}`,
    );
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
