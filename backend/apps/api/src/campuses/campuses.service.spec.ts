import { CampusesService } from './campuses.service';

describe('CampusesService', () => {
  let service: CampusesService;
  let prisma: {
    campusCanteen: { findMany: jest.Mock };
    campusStore: { findMany: jest.Mock };
  };

  beforeEach(() => {
    prisma = {
      campusCanteen: { findMany: jest.fn() },
      campusStore: { findMany: jest.fn() },
    };

    service = new CampusesService(prisma as never);
  });

  it('returns empty canteen floors even when no canteen stores exist', async () => {
    prisma.campusCanteen.findMany.mockResolvedValue([
      {
        id: 'canteen-1',
        name: '东苑一食堂',
        latitude: '32.206443',
        longitude: '118.719779',
        floors: [
          { id: 'floor-1', floorOrder: 1, floorLabel: '1F' },
          { id: 'floor-2', floorOrder: 2, floorLabel: '2F' },
          { id: 'floor-3', floorOrder: 3, floorLabel: '3F' },
        ],
      },
    ]);

    prisma.campusStore.findMany.mockImplementation(async (args: { where: { locationType: string } }) => {
      if (args.where.locationType === 'CANTEEN') {
        return [];
      }

      return [
        {
          id: 'store-1',
          name: '禾香嫂重庆泡脚米线',
          area: '东苑',
          locationType: 'OUTDOOR',
          latitude: '32.206746',
          longitude: '118.721014',
        },
      ];
    });

    const result = await service.listStores('nuist');

    expect(result.canteens).toEqual([
      {
        id: 'canteen-1',
        name: '东苑一食堂',
        latitude: 32.206443,
        longitude: 118.719779,
        floors: [
          { id: 'floor-1', floorOrder: 1, floorLabel: '1F', stores: [] },
          { id: 'floor-2', floorOrder: 2, floorLabel: '2F', stores: [] },
          { id: 'floor-3', floorOrder: 3, floorLabel: '3F', stores: [] },
        ],
      },
    ]);

    expect(result.outdoorStores).toEqual([
      {
        id: 'store-1',
        name: '禾香嫂重庆泡脚米线',
        area: '东苑',
        locationType: 'OUTDOOR',
        canteenId: null,
        canteenName: null,
        floorId: null,
        floorOrder: null,
        floorLabel: null,
        latitude: 32.206746,
        longitude: 118.721014,
      },
    ]);
  });

  it('merges canteen stores into corresponding floor buckets', async () => {
    prisma.campusCanteen.findMany.mockResolvedValue([
      {
        id: 'canteen-1',
        name: '东苑一食堂',
        latitude: '32.206443',
        longitude: '118.719779',
        floors: [{ id: 'floor-1', floorOrder: 1, floorLabel: '1F' }],
      },
    ]);

    prisma.campusStore.findMany.mockImplementation(async (args: { where: { locationType: string } }) => {
      if (args.where.locationType === 'CANTEEN') {
        return [
          {
            id: 'store-2',
            name: '东苑风味面档',
            area: '东苑一食堂 1F',
            locationType: 'CANTEEN',
            latitude: '32.206500',
            longitude: '118.719900',
            floor: {
              id: 'floor-1',
              floorOrder: 1,
              floorLabel: '1F',
              canteen: {
                id: 'canteen-1',
                name: '东苑一食堂',
                latitude: '32.206443',
                longitude: '118.719779',
              },
            },
          },
        ];
      }

      return [];
    });

    const result = await service.listStores('nuist');

    expect(result.canteens[0].floors[0].stores).toEqual([
      {
        id: 'store-2',
        name: '东苑风味面档',
        area: '东苑一食堂 1F',
        locationType: 'CANTEEN',
        canteenId: 'canteen-1',
        canteenName: '东苑一食堂',
        floorId: 'floor-1',
        floorOrder: 1,
        floorLabel: '1F',
        latitude: 32.2065,
        longitude: 118.7199,
      },
    ]);
  });
});
