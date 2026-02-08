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
  area: string;
  latitude: number;
  longitude: number;
  dishes: DishSeed[];
};

const storesSeed: StoreSeed[] = [
  {
    name: '第一食堂·风味面档',
    area: '一食堂',
    latitude: 32.206352,
    longitude: 118.717893,
    dishes: [
      {
        name: '番茄牛肉米线',
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
    area: '一食堂',
    latitude: 32.206101,
    longitude: 118.717512,
    dishes: [
      {
        name: '黑椒鸡腿饭',
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
    name: '第二食堂·铁板饭',
    area: '二食堂',
    latitude: 32.205487,
    longitude: 118.718451,
    dishes: [
      {
        name: '照烧鸡排铁板饭',
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
    area: '二食堂',
    latitude: 32.205731,
    longitude: 118.718197,
    dishes: [
      {
        name: '鸡胸肉藜麦能量碗',
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
    name: '北门早餐铺',
    area: '北门',
    latitude: 32.209386,
    longitude: 118.715984,
    dishes: [
      {
        name: '豆浆 + 鸡蛋灌饼',
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
    area: '东门',
    latitude: 32.204872,
    longitude: 118.720934,
    dishes: [
      {
        name: '微辣牛肉麻辣烫',
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
    const store = await prisma.campusStore.upsert({
      where: {
        campusCode_name_area: {
          campusCode: 'nuist',
          name: storeSeed.name,
          area: storeSeed.area,
        },
      },
      update: {
        latitude: storeSeed.latitude,
        longitude: storeSeed.longitude,
        isOpen: true,
      },
      create: {
        campusCode: 'nuist',
        name: storeSeed.name,
        area: storeSeed.area,
        latitude: storeSeed.latitude,
        longitude: storeSeed.longitude,
        isOpen: true,
      },
    });

    for (const dishSeed of storeSeed.dishes) {
      await prisma.storeDish.upsert({
        where: {
          storeId_name: {
            storeId: store.id,
            name: dishSeed.name,
          },
        },
        update: {
          price: dishSeed.price,
          caloriesKcal: dishSeed.caloriesKcal,
          proteinG: dishSeed.proteinG,
          fatG: dishSeed.fatG,
          carbG: dishSeed.carbG,
          sodiumMg: dishSeed.sodiumMg,
          fiberG: dishSeed.fiberG,
          isAvailable: true,
        },
        create: {
          storeId: store.id,
          name: dishSeed.name,
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

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
