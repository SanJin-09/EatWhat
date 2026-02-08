import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type StoreResponseItem = {
  id: string;
  name: string;
  area: string;
  latitude: number;
  longitude: number;
};

@Injectable()
export class CampusesService {
  constructor(private readonly prisma: PrismaService) {}

  async listStores(campusId: string): Promise<StoreResponseItem[]> {
    const normalizedCampusId = campusId.trim();
    const stores = await this.prisma.campusStore.findMany({
      where: { campusCode: normalizedCampusId },
      orderBy: [{ area: 'asc' }, { name: 'asc' }],
      select: {
        id: true,
        name: true,
        area: true,
        latitude: true,
        longitude: true,
      },
    });

    return stores.map((store) => ({
      id: store.id,
      name: store.name,
      area: store.area,
      latitude: Number(store.latitude),
      longitude: Number(store.longitude),
    }));
  }
}
