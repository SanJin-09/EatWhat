import { Controller, Get, Param, ParseUUIDPipe } from '@nestjs/common';
import { StoresService } from './stores.service';

@Controller('stores')
export class StoresController {
  constructor(private readonly storesService: StoresService) {}

  @Get(':storeId/dishes')
  async getStoreDishes(
    @Param('storeId', new ParseUUIDPipe()) storeId: string,
  ): Promise<{
    dishes: Array<{
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
    }>;
  }> {
    const dishes = await this.storesService.listDishes(storeId);
    return { dishes };
  }
}
