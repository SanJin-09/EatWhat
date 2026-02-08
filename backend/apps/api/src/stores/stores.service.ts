import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type DishResponseItem = {
  id: string;
  storeId: string;
  name: string;
  price: number | null;
  nutrition: {
    caloriesKcal: number;
    proteinG: number;
    fatG: number;
    carbG: number;
    sodiumMg: number;
    fiberG: number;
  } | null;
};

@Injectable()
export class StoresService {
  constructor(private readonly prisma: PrismaService) {}

  async listDishes(storeId: string): Promise<DishResponseItem[]> {
    const store = await this.prisma.campusStore.findUnique({
      where: { id: storeId },
      select: { id: true },
    });

    if (!store) {
      throw new NotFoundException('店铺不存在。');
    }

    const dishes = await this.prisma.storeDish.findMany({
      where: { storeId, isAvailable: true },
      orderBy: { name: 'asc' },
      select: {
        id: true,
        storeId: true,
        name: true,
        price: true,
        caloriesKcal: true,
        proteinG: true,
        fatG: true,
        carbG: true,
        sodiumMg: true,
        fiberG: true,
      },
    });

    return dishes.map((dish) => {
      const hasNutrition =
        dish.caloriesKcal !== null &&
        dish.proteinG !== null &&
        dish.fatG !== null &&
        dish.carbG !== null &&
        dish.sodiumMg !== null &&
        dish.fiberG !== null;

      return {
        id: dish.id,
        storeId: dish.storeId,
        name: dish.name,
        price: dish.price === null ? null : Number(dish.price),
        nutrition: hasNutrition
          ? {
              caloriesKcal: Number(dish.caloriesKcal),
              proteinG: Number(dish.proteinG),
              fatG: Number(dish.fatG),
              carbG: Number(dish.carbG),
              sodiumMg: Number(dish.sodiumMg),
              fiberG: Number(dish.fiberG),
            }
          : null,
      };
    });
  }
}
