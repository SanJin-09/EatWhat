import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type StoreResponseItem = {
  id: string;
  name: string;
  area: string;
  locationType: 'CANTEEN' | 'OUTDOOR';
  canteenId: string | null;
  canteenName: string | null;
  floorId: string | null;
  floorOrder: number | null;
  floorLabel: string | null;
  latitude: number;
  longitude: number;
};

type FloorResponseItem = {
  id: string;
  floorOrder: number;
  floorLabel: string;
  stores: StoreResponseItem[];
};

type CanteenResponseItem = {
  id: string;
  name: string;
  floors: FloorResponseItem[];
};

type CampusStoresResponse = {
  canteens: CanteenResponseItem[];
  outdoorStores: StoreResponseItem[];
};

@Injectable()
export class CampusesService {
  constructor(private readonly prisma: PrismaService) {}

  async listStores(campusId: string): Promise<CampusStoresResponse> {
    const normalizedCampusId = campusId.trim();

    const canteenStores = await this.prisma.campusStore.findMany({
      where: {
        campusCode: normalizedCampusId,
        locationType: 'CANTEEN',
      },
      orderBy: [{ floor: { canteen: { name: 'asc' } } }, { floor: { floorOrder: 'asc' } }, { name: 'asc' }],
      select: {
        id: true,
        name: true,
        area: true,
        locationType: true,
        latitude: true,
        longitude: true,
        floor: {
          select: {
            id: true,
            floorOrder: true,
            floorLabel: true,
            canteen: {
              select: {
                id: true,
                name: true,
              },
            },
          },
        },
      },
    });

    const outdoorStores = await this.prisma.campusStore.findMany({
      where: {
        campusCode: normalizedCampusId,
        locationType: 'OUTDOOR',
      },
      orderBy: [{ area: 'asc' }, { name: 'asc' }],
      select: {
        id: true,
        name: true,
        area: true,
        locationType: true,
        latitude: true,
        longitude: true,
      },
    });

    const canteenMap = new Map<string, { id: string; name: string; floorMap: Map<string, FloorResponseItem> }>();

    for (const store of canteenStores) {
      if (!store.floor) {
        continue;
      }

      const canteenId = store.floor.canteen.id;
      const canteenName = store.floor.canteen.name;
      const floorId = store.floor.id;

      if (!canteenMap.has(canteenId)) {
        canteenMap.set(canteenId, {
          id: canteenId,
          name: canteenName,
          floorMap: new Map<string, FloorResponseItem>(),
        });
      }

      const canteen = canteenMap.get(canteenId);
      if (!canteen) {
        continue;
      }

      if (!canteen.floorMap.has(floorId)) {
        canteen.floorMap.set(floorId, {
          id: floorId,
          floorOrder: store.floor.floorOrder,
          floorLabel: store.floor.floorLabel,
          stores: [],
        });
      }

      const floor = canteen.floorMap.get(floorId);
      if (!floor) {
        continue;
      }

      floor.stores.push({
        id: store.id,
        name: store.name,
        area: store.area,
        locationType: store.locationType,
        canteenId,
        canteenName,
        floorId,
        floorOrder: store.floor.floorOrder,
        floorLabel: store.floor.floorLabel,
        latitude: Number(store.latitude),
        longitude: Number(store.longitude),
      });
    }

    return {
      canteens: Array.from(canteenMap.values()).map((canteen) => ({
        id: canteen.id,
        name: canteen.name,
        floors: Array.from(canteen.floorMap.values()),
      })),
      outdoorStores: outdoorStores.map((store) => ({
        id: store.id,
        name: store.name,
        area: store.area,
        locationType: store.locationType,
        canteenId: null,
        canteenName: null,
        floorId: null,
        floorOrder: null,
        floorLabel: null,
        latitude: Number(store.latitude),
        longitude: Number(store.longitude),
      })),
    };
  }
}
