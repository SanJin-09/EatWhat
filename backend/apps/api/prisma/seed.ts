import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
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
  area: string;
  latitude: number;
  longitude: number;
  dishes: DishSeed[];
};

const storesSeed: StoreSeed[] = [
  {
    name: 'First Canteen - Noodle Bar',
    legacyName: '第一食堂·风味面档',
    area: '一食堂',
    latitude: 32.206352,
    longitude: 118.717893,
    dishes: [
      {
        name: 'Tomato Beef Rice Noodles',
        legacyName: '番茄牛肉米线',
        price: 15,
        caloriesKcal: 680,
        proteinG: 28,
        fatG: 21,
        carbG: 92,
        sodiumMg: 1150,
        fiberG: 4.2,
      },
      {
        name: 'Hot and Sour Beef Rice Noodles',
        legacyName: '酸辣肥牛粉',
        price: 16,
        caloriesKcal: 720,
        proteinG: 27,
        fatG: 24,
        carbG: 96,
        sodiumMg: 1320,
        fiberG: 3.8,
      },
      {
        name: 'Mushroom Chicken Soup Noodles',
        legacyName: '菌菇鸡汤面',
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
    name: 'First Canteen - Fast Combo',
    legacyName: '第一食堂·快餐自选',
    area: '一食堂',
    latitude: 32.206101,
    longitude: 118.717512,
    dishes: [
      {
        name: 'Black Pepper Chicken Leg Rice',
        legacyName: '黑椒鸡腿饭',
        price: 18,
        caloriesKcal: 760,
        proteinG: 35,
        fatG: 26,
        carbG: 95,
        sodiumMg: 1280,
        fiberG: 5.3,
      },
      {
        name: 'Braised Beef Brisket with Potato Set',
        legacyName: '土豆牛腩套餐',
        price: 19,
        caloriesKcal: 780,
        proteinG: 33,
        fatG: 29,
        carbG: 96,
        sodiumMg: 1400,
        fiberG: 5.1,
      },
      {
        name: 'Mushroom and Greens Rice',
        legacyName: '香菇青菜盖浇饭',
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
  {
    name: 'Second Canteen - Teppanyaki Rice',
    legacyName: '第二食堂·铁板饭',
    area: '二食堂',
    latitude: 32.205487,
    longitude: 118.718451,
    dishes: [
      {
        name: 'Teriyaki Chicken Steak Iron Plate Rice',
        legacyName: '照烧鸡排铁板饭',
        price: 20,
        caloriesKcal: 840,
        proteinG: 37,
        fatG: 31,
        carbG: 102,
        sodiumMg: 1480,
        fiberG: 4.7,
      },
      {
        name: 'Black Pepper Beef Strips Iron Plate Noodles',
        legacyName: '黑胡椒牛柳铁板面',
        price: 21,
        caloriesKcal: 860,
        proteinG: 34,
        fatG: 33,
        carbG: 104,
        sodiumMg: 1510,
        fiberG: 4.1,
      },
      {
        name: 'Cumin Chicken Dice Iron Plate Rice',
        legacyName: '孜然鸡丁铁板饭',
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
    name: 'Second Canteen - Light Energy Bowl',
    legacyName: '第二食堂·轻食能量碗',
    area: '二食堂',
    latitude: 32.205731,
    longitude: 118.718197,
    dishes: [
      {
        name: 'Chicken Breast Quinoa Power Bowl',
        legacyName: '鸡胸肉藜麦能量碗',
        price: 22,
        caloriesKcal: 510,
        proteinG: 38,
        fatG: 14,
        carbG: 52,
        sodiumMg: 680,
        fiberG: 8.6,
      },
      {
        name: 'Beef and Veg Whole Wheat Bowl',
        legacyName: '牛肉时蔬全麦碗',
        price: 24,
        caloriesKcal: 560,
        proteinG: 35,
        fatG: 18,
        carbG: 58,
        sodiumMg: 740,
        fiberG: 9.1,
      },
      {
        name: 'Tuna Corn Salad Bowl',
        legacyName: '金枪鱼玉米沙拉碗',
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
  {
    name: 'North Gate Breakfast Stall',
    legacyName: '北门早餐铺',
    area: '北门',
    latitude: 32.209386,
    longitude: 118.715984,
    dishes: [
      {
        name: 'Soy Milk + Egg Pancake',
        legacyName: '豆浆 + 鸡蛋灌饼',
        price: 9,
        caloriesKcal: 460,
        proteinG: 16,
        fatG: 17,
        carbG: 62,
        sodiumMg: 720,
        fiberG: 2.7,
      },
      {
        name: 'Pork Congee + Soup Dumplings',
        legacyName: '皮蛋瘦肉粥 + 小笼包',
        price: 10,
        caloriesKcal: 510,
        proteinG: 20,
        fatG: 14,
        carbG: 74,
        sodiumMg: 890,
        fiberG: 2.2,
      },
      {
        name: 'Beef Potstickers + Tofu Pudding',
        legacyName: '牛肉锅贴 + 豆腐脑',
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
    name: 'East Gate Mala Tang',
    legacyName: '东门麻辣烫',
    area: '东门',
    latitude: 32.204872,
    longitude: 118.720934,
    dishes: [
      {
        name: 'Mild Spicy Beef Mala Tang',
        legacyName: '微辣牛肉麻辣烫',
        price: 20,
        caloriesKcal: 690,
        proteinG: 30,
        fatG: 22,
        carbG: 86,
        sodiumMg: 1620,
        fiberG: 6.1,
      },
      {
        name: 'Tomato Broth Mala Tang',
        legacyName: '番茄浓汤麻辣烫',
        price: 19,
        caloriesKcal: 650,
        proteinG: 26,
        fatG: 20,
        carbG: 84,
        sodiumMg: 1410,
        fiberG: 6.4,
      },
      {
        name: 'Mushroom Clear Broth Mala Tang',
        legacyName: '菌菇清汤麻辣烫',
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
    name: 'Buruma Mala Tang',
    legacyName: '不如麻浪烫',
    area: '东门',
    latitude: 32.205128,
    longitude: 118.720412,
    dishes: [
      {
        name: 'Mala Tang',
        legacyName: '麻辣烫',
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
    name: 'Li Bao Zhang',
    legacyName: '李煲长',
    area: '北门',
    latitude: 32.208941,
    longitude: 118.716808,
    dishes: [
      {
        name: 'Braised Chicken Rice',
        legacyName: '黄焖鸡米饭',
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

async function main(): Promise<void> {
  await prisma.campus.upsert({
    where: { code: 'nuist' },
    update: {
      name: '南京信息工程大学',
      city: '南京',
      centerLat: 32.205515,
      centerLng: 118.717502,
    },
    create: {
      code: 'nuist',
      name: '南京信息工程大学',
      city: '南京',
      centerLat: 32.205515,
      centerLng: 118.717502,
    },
  });

  for (const storeSeed of storesSeed) {
    const storeNameCandidates = [storeSeed.name, storeSeed.legacyName].filter(
      (value): value is string => Boolean(value),
    );

    const existingStore = await prisma.campusStore.findFirst({
      where: {
        campusCode: 'nuist',
        area: storeSeed.area,
        name: { in: storeNameCandidates },
      },
      select: { id: true },
    });

    const store = existingStore
      ? await prisma.campusStore.update({
          where: { id: existingStore.id },
          data: {
            name: storeSeed.name,
            latitude: storeSeed.latitude,
            longitude: storeSeed.longitude,
            isOpen: true,
          },
        })
      : await prisma.campusStore.create({
          data: {
            campusCode: 'nuist',
            name: storeSeed.name,
            area: storeSeed.area,
            latitude: storeSeed.latitude,
            longitude: storeSeed.longitude,
            isOpen: true,
          },
        });

    for (const dishSeed of storeSeed.dishes) {
      const dishNameCandidates = [dishSeed.name, dishSeed.legacyName].filter(
        (value): value is string => Boolean(value),
      );

      const existingDish = await prisma.storeDish.findFirst({
        where: {
          storeId: store.id,
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
      } else {
        await prisma.storeDish.create({
          data: {
            storeId: store.id,
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
