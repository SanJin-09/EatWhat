import { Controller, Get, Param } from '@nestjs/common';
import { CampusesService } from './campuses.service';

@Controller('campuses')
export class CampusesController {
  constructor(private readonly campusesService: CampusesService) {}

  @Get(':campusId/stores')
  async getCampusStores(@Param('campusId') campusId: string): Promise<{
    stores: Array<{
      id: string;
      name: string;
      area: string;
      latitude: number;
      longitude: number;
    }>;
  }> {
    const stores = await this.campusesService.listStores(campusId);
    return { stores };
  }
}
