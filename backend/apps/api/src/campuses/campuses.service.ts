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
  latitude: number | null;
  longitude: number | null;
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

    const canteens = await this.prisma.campusCanteen.findMany({
      where: {
        campusCode: normalizedCampusId,
      },
      orderBy: [{ name: 'asc' }],
      select: {
        id: true,
        name: true,
        latitude: true,
        longitude: true,
        floors: {
          orderBy: [{ floorOrder: 'asc' }],
          select: {
            id: true,
            floorOrder: true,
            floorLabel: true,
          },
        },
      },
    });

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
                latitude: true,
                longitude: true,
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

    const canteenMap = new Map<
      string,
      {
        id: string;
        name: string;
        latitude: number | null;
        longitude: number | null;
        floorMap: Map<string, FloorResponseItem>;
      }
    >();

    for (const canteen of canteens) {
      canteenMap.set(canteen.id, {
        id: canteen.id,
        name: canteen.name,
        latitude: canteen.latitude === null ? null : Number(canteen.latitude),
        longitude: canteen.longitude === null ? null : Number(canteen.longitude),
        floorMap: new Map(
          canteen.floors.map((floor) => [
            floor.id,
            {
              id: floor.id,
              floorOrder: floor.floorOrder,
              floorLabel: floor.floorLabel,
              stores: [],
            },
          ]),
        ),
      });
    }

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
          latitude: store.floor.canteen.latitude === null ? null : Number(store.floor.canteen.latitude),
          longitude: store.floor.canteen.longitude === null ? null : Number(store.floor.canteen.longitude),
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
      canteens: Array.from(canteenMap.values())
        .sort((lhs, rhs) => lhs.name.localeCompare(rhs.name, 'zh-Hans-CN'))
        .map((canteen) => ({
          id: canteen.id,
          name: canteen.name,
          latitude: canteen.latitude,
          longitude: canteen.longitude,
          floors: Array.from(canteen.floorMap.values()).sort(
            (lhs, rhs) =>
              lhs.floorOrder - rhs.floorOrder || lhs.floorLabel.localeCompare(rhs.floorLabel, 'en'),
          ),
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
