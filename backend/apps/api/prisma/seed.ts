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
  floors: CanteenFloorSeed[];
};

type OutdoorStoreSeed = StoreSeed & {
  area: string;
};

const defaultCampusCode = 'nuist';

const canteensSeed: CanteenSeed[] = [
  {
    name: '一食堂',
    floors: [
      {
        floorOrder: 1,
        floorLabel: '1F',
        stores: [
          {
            name: '第一食堂·风味面档',
            legacyName: 'First Canteen - Noodle Bar',
            latitude: 32.206352,
            longitude: 118.717893,
            dishes: [
              {
                name: '番茄牛肉米线',
                legacyName: 'Tomato Beef Rice Noodles',
                price: 15,
                caloriesKcal: 680,
                proteinG: 28,
                fatG: 21,
                carbG: 92,
                sodiumMg: 1150,
                fiberG: 4.2,
              },
              {
                name: '酸辣肥牛粉',
                legacyName: 'Hot and Sour Beef Rice Noodles',
                price: 16,
                caloriesKcal: 720,
                proteinG: 27,
                fatG: 24,
                carbG: 96,
                sodiumMg: 1320,
                fiberG: 3.8,
              },
              {
                name: '菌菇鸡汤面',
                legacyName: 'Mushroom Chicken Soup Noodles',
                price: 14,
                caloriesKcal: 610,
                proteinG: 24,
                fatG: 17,
                carbG: 88,
                sodiumMg: 980,
                fiberG: 4.5,
              },
            ],
          },
          {
            name: '第一食堂·快餐自选',
            legacyName: 'First Canteen - Fast Combo',
            latitude: 32.206101,
            longitude: 118.717512,
            dishes: [
              {
                name: '黑椒鸡腿饭',
                legacyName: 'Black Pepper Chicken Leg Rice',
                price: 18,
                caloriesKcal: 760,
                proteinG: 35,
                fatG: 26,
                carbG: 95,
                sodiumMg: 1280,
                fiberG: 5.3,
              },
              {
                name: '土豆牛腩套餐',
                legacyName: 'Braised Beef Brisket with Potato Set',
                price: 19,
                caloriesKcal: 780,
                proteinG: 33,
                fatG: 29,
                carbG: 96,
                sodiumMg: 1400,
                fiberG: 5.1,
              },
              {
                name: '香菇青菜盖浇饭',
                legacyName: 'Mushroom and Greens Rice',
                price: 13,
                caloriesKcal: 620,
                proteinG: 16,
                fatG: 18,
                carbG: 94,
                sodiumMg: 860,
                fiberG: 6.8,
              },
            ],
          },
        ],
      },
    ],
  },
  {
    name: '二食堂',
    floors: [
      {
        floorOrder: 1,
        floorLabel: '1F',
        stores: [
          {
            name: '第二食堂·铁板饭',
            legacyName: 'Second Canteen - Teppanyaki Rice',
            latitude: 32.205487,
            longitude: 118.718451,
            dishes: [
              {
                name: '照烧鸡排铁板饭',
                legacyName: 'Teriyaki Chicken Steak Iron Plate Rice',
                price: 20,
                caloriesKcal: 840,
                proteinG: 37,
                fatG: 31,
                carbG: 102,
                sodiumMg: 1480,
                fiberG: 4.7,
              },
              {
                name: '黑胡椒牛柳铁板面',
                legacyName: 'Black Pepper Beef Strips Iron Plate Noodles',
                price: 21,
                caloriesKcal: 860,
                proteinG: 34,
                fatG: 33,
                carbG: 104,
                sodiumMg: 1510,
                fiberG: 4.1,
              },
              {
                name: '孜然鸡丁铁板饭',
                legacyName: 'Cumin Chicken Dice Iron Plate Rice',
                price: 18,
                caloriesKcal: 780,
                proteinG: 32,
                fatG: 27,
                carbG: 97,
                sodiumMg: 1320,
                fiberG: 4.4,
              },
            ],
          },
          {
            name: '第二食堂·轻食能量碗',
            legacyName: 'Second Canteen - Light Energy Bowl',
            latitude: 32.205731,
            longitude: 118.718197,
            dishes: [
              {
                name: '鸡胸肉藜麦能量碗',
                legacyName: 'Chicken Breast Quinoa Power Bowl',
                price: 22,
                caloriesKcal: 510,
                proteinG: 38,
                fatG: 14,
                carbG: 52,
                sodiumMg: 680,
                fiberG: 8.6,
              },
              {
                name: '牛肉时蔬全麦碗',
                legacyName: 'Beef and Veg Whole Wheat Bowl',
                price: 24,
                caloriesKcal: 560,
                proteinG: 35,
                fatG: 18,
                carbG: 58,
                sodiumMg: 740,
                fiberG: 9.1,
              },
              {
                name: '金枪鱼玉米沙拉碗',
                legacyName: 'Tuna Corn Salad Bowl',
                price: 21,
                caloriesKcal: 470,
                proteinG: 29,
                fatG: 16,
                carbG: 49,
                sodiumMg: 620,
                fiberG: 7.3,
              },
            ],
          },
        ],
      },
    ],
  },
];

const outdoorStoresSeed: OutdoorStoreSeed[] = [
  {
    name: '北门早餐铺',
    legacyName: 'North Gate Breakfast Stall',
    area: '北门',
    latitude: 32.209386,
    longitude: 118.715984,
    dishes: [
      {
        name: '豆浆 + 鸡蛋灌饼',
        legacyName: 'Soy Milk + Egg Pancake',
        price: 9,
        caloriesKcal: 460,
        proteinG: 16,
        fatG: 17,
        carbG: 62,
        sodiumMg: 720,
        fiberG: 2.7,
      },
      {
        name: '皮蛋瘦肉粥 + 小笼包',
        legacyName: 'Pork Congee + Soup Dumplings',
        price: 10,
        caloriesKcal: 510,
        proteinG: 20,
        fatG: 14,
        carbG: 74,
        sodiumMg: 890,
        fiberG: 2.2,
      },
      {
        name: '牛肉锅贴 + 豆腐脑',
        legacyName: 'Beef Potstickers + Tofu Pudding',
        price: 11,
        caloriesKcal: 540,
        proteinG: 22,
        fatG: 19,
        carbG: 68,
        sodiumMg: 970,
        fiberG: 2.4,
      },
    ],
  },
  {
    name: '东门麻辣烫',
    legacyName: 'East Gate Mala Tang',
    area: '东门',
    latitude: 32.204872,
    longitude: 118.720934,
    dishes: [
      {
        name: '微辣牛肉麻辣烫',
        legacyName: 'Mild Spicy Beef Mala Tang',
        price: 20,
        caloriesKcal: 690,
        proteinG: 30,
        fatG: 22,
        carbG: 86,
        sodiumMg: 1620,
        fiberG: 6.1,
      },
      {
        name: '番茄浓汤麻辣烫',
        legacyName: 'Tomato Broth Mala Tang',
        price: 19,
        caloriesKcal: 650,
        proteinG: 26,
        fatG: 20,
        carbG: 84,
        sodiumMg: 1410,
        fiberG: 6.4,
      },
      {
        name: '菌菇清汤麻辣烫',
        legacyName: 'Mushroom Clear Broth Mala Tang',
        price: 18,
        caloriesKcal: 610,
        proteinG: 24,
        fatG: 17,
        carbG: 82,
        sodiumMg: 1280,
        fiberG: 7.2,
      },
    ],
  },
  {
    name: '不如麻浪烫',
    legacyName: 'Buruma Mala Tang',
    area: '东门',
    latitude: 32.205128,
    longitude: 118.720412,
    dishes: [
      {
        name: '麻辣烫',
        legacyName: 'Mala Tang',
        price: 20,
        caloriesKcal: 450,
        proteinG: 28,
        fatG: 13,
        carbG: 52,
        sodiumMg: 1370,
        fiberG: 5.5,
      },
    ],
  },
  {
    name: '李煲长',
    legacyName: 'Li Bao Zhang',
    area: '北门',
    latitude: 32.208941,
    longitude: 118.716808,
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

async function upsertStoreDishes(storeId: string, dishes: DishSeed[]): Promise<void> {
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
      continue;
    }

    await prisma.storeDish.create({
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
    });
  }
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

async function upsertCampusStore(input: UpsertCampusStoreInput): Promise<void> {
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
      });

  await upsertStoreDishes(store.id, input.dishes);
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
      },
      create: {
        campusCode: defaultCampusCode,
        name: canteenSeed.name,
      },
    });

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
      });

      for (const storeSeed of floorSeed.stores) {
        await upsertCampusStore({
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
      }
    }
  }

  for (const storeSeed of outdoorStoresSeed) {
    await upsertCampusStore({
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
  }
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
