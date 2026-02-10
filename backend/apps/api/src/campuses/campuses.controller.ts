import { Controller, Get, Param } from '@nestjs/common';
import { CampusesService } from './campuses.service';

@Controller('campuses')
export class CampusesController {
  constructor(private readonly campusesService: CampusesService) {}

  @Get(':campusId/stores')
  async getCampusStores(@Param('campusId') campusId: string) {
    return this.campusesService.listStores(campusId);
  }
}
