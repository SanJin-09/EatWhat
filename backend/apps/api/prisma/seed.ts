import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, StoreLocationType } from '@prisma/client';
import { Pool } from 'pg';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is missing.');
}

const prisma = new PrismaClient({
  adapter: new PrismaPg(
    new Pool({
      connectionString,
    }),
  ),
});

type DishSeed = {
  name: string;
  legacyName?: string;
  imageKey?: string;
  price: number;
  caloriesKcal: number;
  proteinG: number;
  fatG: number;
  carbG: number;
  sodiumMg: number;
  fiberG: number;
};

type StoreSeed = {
  name: string;
  legacyName?: string;
  latitude: number;
  longitude: number;
  dishes: DishSeed[];
};

type CanteenFloorSeed = {
  floorOrder: number;
  floorLabel: string;
  stores: StoreSeed[];
};

type CanteenSeed = {
  name: string;
  latitude: number;
  longitude: number;
  floors: CanteenFloorSeed[];
};

type OutdoorStoreSeed = StoreSeed & {
  area: string;
};

const defaultCampusCode = 'nuist';

const canteensSeed: CanteenSeed[] = [
  {
    name: '东苑一食堂',
    latitude: 32.206443,
    longitude: 118.719779,
    floors: [
      {
        floorOrder: 1,
        floorLabel: '1F',
        stores: [],
      },
      {
        floorOrder: 2,
        floorLabel: '2F',
        stores: [],
      },
      {
        floorOrder: 3,
        floorLabel: '3F',
        stores: [],
      },
    ],
  },
];

const outdoorStoresSeed: OutdoorStoreSeed[] = [
  {
    name: '禾香嫂重庆泡脚米线',
    area: '东苑',
    latitude: 32.206746,
    longitude: 118.721014,
    dishes: [
      {
        name: '冰豆花',
        price: 2,
        caloriesKcal: 120,
        proteinG: 3.5,
        fatG: 2.8,
        carbG: 22,
        sodiumMg: 80,
        fiberG: 0.6,
      },
      {
        name: '碗杂面',
        price: 12,
        caloriesKcal: 610,
        proteinG: 19,
        fatG: 17,
        carbG: 93,
        sodiumMg: 1450,
        fiberG: 4.3,
      },
    ],
  },
  {
    name: '李煲长鲜煲黄焖鸡',
    legacyName: '李煲长',
    area: '北门',
    latitude: 32.206713,
    longitude: 118.720821,
    dishes: [
      {
        name: '黄焖鸡米饭',
        legacyName: 'Braised Chicken Rice',
        price: 16,
        caloriesKcal: 470,
        proteinG: 27,
        fatG: 15,
        carbG: 57,
        sodiumMg: 1300,
        fiberG: 1.1,
      },
    ],
  },
];

function compactCandidates(...values: Array<string | undefined>): string[] {
  return Array.from(
    new Set(
      values
        .map((value) => value?.trim())
        .filter((value): value is string => Boolean(value)),
    ),
  );
}

async function upsertStoreDishes(storeId: string, dishes: DishSeed[]): Promise<string[]> {
  const keepDishIds: string[] = [];

  for (const dishSeed of dishes) {
    const dishNameCandidates = compactCandidates(dishSeed.name, dishSeed.legacyName);

    const existingDish = await prisma.storeDish.findFirst({
      where: {
        storeId,
        name: { in: dishNameCandidates },
      },
      select: { id: true },
    });

    if (existingDish) {
      await prisma.storeDish.update({
        where: { id: existingDish.id },
        data: {
          name: dishSeed.name,
          imageKey: dishSeed.imageKey ?? null,
          price: dishSeed.price,
          caloriesKcal: dishSeed.caloriesKcal,
          proteinG: dishSeed.proteinG,
          fatG: dishSeed.fatG,
          carbG: dishSeed.carbG,
          sodiumMg: dishSeed.sodiumMg,
          fiberG: dishSeed.fiberG,
          isAvailable: true,
        },
      });
      keepDishIds.push(existingDish.id);
      continue;
    }

    const createdDish = await prisma.storeDish.create({
      data: {
        storeId,
        name: dishSeed.name,
        imageKey: dishSeed.imageKey ?? null,
        price: dishSeed.price,
        caloriesKcal: dishSeed.caloriesKcal,
        proteinG: dishSeed.proteinG,
        fatG: dishSeed.fatG,
        carbG: dishSeed.carbG,
        sodiumMg: dishSeed.sodiumMg,
        fiberG: dishSeed.fiberG,
        isAvailable: true,
      },
      select: { id: true },
    });

    keepDishIds.push(createdDish.id);
  }

  if (keepDishIds.length === 0) {
    await prisma.storeDish.deleteMany({
      where: {
        storeId,
      },
    });
    return keepDishIds;
  }

  await prisma.storeDish.deleteMany({
    where: {
      storeId,
      id: { notIn: keepDishIds },
    },
  });

  return keepDishIds;
}

type UpsertCampusStoreInput = {
  campusCode: string;
  name: string;
  legacyName?: string;
  area: string;
  fallbackAreas?: string[];
  latitude: number;
  longitude: number;
  locationType: StoreLocationType;
  floorId: string | null;
  dishes: DishSeed[];
};

type UpsertCampusStoreResult = {
  id: string;
  dishIds: string[];
};

async function upsertCampusStore(input: UpsertCampusStoreInput): Promise<UpsertCampusStoreResult> {
  const storeNameCandidates = compactCandidates(input.name, input.legacyName);
  const areaCandidates = compactCandidates(input.area, ...(input.fallbackAreas ?? []));

  let existingStore: { id: string } | null = null;

  if (input.locationType === StoreLocationType.CANTEEN && input.floorId) {
    existingStore = await prisma.campusStore.findFirst({
      where: {
        campusCode: input.campusCode,
        floorId: input.floorId,
        name: { in: storeNameCandidates },
      },
      select: { id: true },
    });
  }

  if (!existingStore) {
    existingStore = await prisma.campusStore.findFirst({
      where: {
        campusCode: input.campusCode,
        name: { in: storeNameCandidates },
        area: { in: areaCandidates },
      },
      select: { id: true },
    });
  }

  const store = existingStore
    ? await prisma.campusStore.update({
        where: { id: existingStore.id },
        data: {
          name: input.name,
          area: input.area,
          locationType: input.locationType,
          floorId: input.floorId,
          latitude: input.latitude,
          longitude: input.longitude,
          isOpen: true,
        },
        select: { id: true },
      })
    : await prisma.campusStore.create({
        data: {
          campusCode: input.campusCode,
          name: input.name,
          area: input.area,
          locationType: input.locationType,
          floorId: input.floorId,
          latitude: input.latitude,
          longitude: input.longitude,
          isOpen: true,
        },
        select: { id: true },
      });

  const keepDishIds = await upsertStoreDishes(store.id, input.dishes);

  return {
    id: store.id,
    dishIds: keepDishIds,
  };
}

async function clearUnmentionedData(input: {
  keepStoreIds: Set<string>;
  keepFloorIds: Set<string>;
  keepCanteenIds: Set<string>;
  keepDishIds: Set<string>;
}): Promise<void> {
  const keepStoreIds = Array.from(input.keepStoreIds);
  const keepFloorIds = Array.from(input.keepFloorIds);
  const keepCanteenIds = Array.from(input.keepCanteenIds);
  const keepDishIds = Array.from(input.keepDishIds);

  if (keepStoreIds.length > 0) {
    await prisma.campusStore.deleteMany({
      where: {
        id: { notIn: keepStoreIds },
      },
    });
  } else {
    await prisma.campusStore.deleteMany({});
  }

  if (keepFloorIds.length > 0) {
    await prisma.canteenFloor.deleteMany({
      where: {
        id: { notIn: keepFloorIds },
      },
    });
  } else {
    await prisma.canteenFloor.deleteMany({});
  }

  if (keepCanteenIds.length > 0) {
    await prisma.campusCanteen.deleteMany({
      where: {
        id: { notIn: keepCanteenIds },
      },
    });
  } else {
    await prisma.campusCanteen.deleteMany({});
  }

  if (keepDishIds.length > 0) {
    await prisma.storeDish.deleteMany({
      where: {
        id: { notIn: keepDishIds },
      },
    });
  } else {
    await prisma.storeDish.deleteMany({});
  }
}

async function main(): Promise<void> {
  await prisma.campus.upsert({
    where: { code: defaultCampusCode },
    update: {
      name: '南京信息工程大学',
      city: '南京',
      centerLat: 32.205515,
      centerLng: 118.717502,
    },
    create: {
      code: defaultCampusCode,
      name: '南京信息工程大学',
      city: '南京',
      centerLat: 32.205515,
      centerLng: 118.717502,
    },
  });

  const keepCanteenIds = new Set<string>();
  const keepFloorIds = new Set<string>();
  const keepStoreIds = new Set<string>();
  const keepDishIds = new Set<string>();

  for (const canteenSeed of canteensSeed) {
    const canteen = await prisma.campusCanteen.upsert({
      where: {
        campusCode_name: {
          campusCode: defaultCampusCode,
          name: canteenSeed.name,
        },
      },
      update: {
        name: canteenSeed.name,
        latitude: canteenSeed.latitude,
        longitude: canteenSeed.longitude,
      },
      create: {
        campusCode: defaultCampusCode,
        name: canteenSeed.name,
        latitude: canteenSeed.latitude,
        longitude: canteenSeed.longitude,
      },
      select: {
        id: true,
      },
    });

    keepCanteenIds.add(canteen.id);

    for (const floorSeed of canteenSeed.floors) {
      const floor = await prisma.canteenFloor.upsert({
        where: {
          canteenId_floorOrder: {
            canteenId: canteen.id,
            floorOrder: floorSeed.floorOrder,
          },
        },
        update: {
          floorLabel: floorSeed.floorLabel,
        },
        create: {
          canteenId: canteen.id,
          floorOrder: floorSeed.floorOrder,
          floorLabel: floorSeed.floorLabel,
        },
        select: {
          id: true,
        },
      });

      keepFloorIds.add(floor.id);

      for (const storeSeed of floorSeed.stores) {
        const store = await upsertCampusStore({
          campusCode: defaultCampusCode,
          name: storeSeed.name,
          legacyName: storeSeed.legacyName,
          area: `${canteenSeed.name} ${floorSeed.floorLabel}`,
          fallbackAreas: [canteenSeed.name],
          latitude: storeSeed.latitude,
          longitude: storeSeed.longitude,
          locationType: StoreLocationType.CANTEEN,
          floorId: floor.id,
          dishes: storeSeed.dishes,
        });

        keepStoreIds.add(store.id);
        for (const dishId of store.dishIds) {
          keepDishIds.add(dishId);
        }
      }
    }
  }

  for (const storeSeed of outdoorStoresSeed) {
    const store = await upsertCampusStore({
      campusCode: defaultCampusCode,
      name: storeSeed.name,
      legacyName: storeSeed.legacyName,
      area: storeSeed.area,
      latitude: storeSeed.latitude,
      longitude: storeSeed.longitude,
      locationType: StoreLocationType.OUTDOOR,
      floorId: null,
      dishes: storeSeed.dishes,
    });

    keepStoreIds.add(store.id);
    for (const dishId of store.dishIds) {
      keepDishIds.add(dishId);
    }
  }

  await clearUnmentionedData({
    keepStoreIds,
    keepFloorIds,
    keepCanteenIds,
    keepDishIds,
  });

  console.log(
    `Seed completed. keepCanteens=${keepCanteenIds.size}, keepFloors=${keepFloorIds.size}, keepStores=${keepStoreIds.size}, keepDishes=${keepDishIds.size}`,
  );
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
