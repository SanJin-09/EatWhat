import Foundation
import CoreDomain

public actor MockCampusMenuRepository: CampusMenuRepository {
    public static let nuistCampusID = "nuist"

    private let campusId: String
    private let stores: [CampusStoreOption]
    private let dishesByStoreID: [UUID: [CampusDishOption]]

    public init(campusId: String = MockCampusMenuRepository.nuistCampusID) {
        self.campusId = campusId

        let firstCanteenNoodleID = UUID(uuidString: "0BEFB7EE-9BC5-402C-9802-F18CFD784E2D")!
        let secondCanteenRiceID = UUID(uuidString: "8D3A3A66-D8FC-4E31-A58F-B00A8B535D6A")!
        let halalWindowID = UUID(uuidString: "A43DC997-7CB1-4455-B43A-B0A9D1DD95F8")!
        let northGateBreakfastID = UUID(uuidString: "4FCFC3BB-E108-4C72-B47A-A0E978D632E5")!
        let eastGardenLightMealID = UUID(uuidString: "63D6E8B7-C85A-499D-814D-BD83F3A89F84")!
        let westGardenMalaTangID = UUID(uuidString: "B4933D26-07D7-45EC-B704-B4A8B97A62D4")!

        stores = [
            CampusStoreOption(
                id: firstCanteenNoodleID,
                campusId: campusId,
                name: "一食堂米线档",
                area: "一食堂",
                coordinate: CampusCoordinate(latitude: 32.2050, longitude: 118.7168)
            ),
            CampusStoreOption(
                id: secondCanteenRiceID,
                campusId: campusId,
                name: "二食堂盖浇饭",
                area: "二食堂",
                coordinate: CampusCoordinate(latitude: 32.2077, longitude: 118.7204)
            ),
            CampusStoreOption(
                id: halalWindowID,
                campusId: campusId,
                name: "清真窗口",
                area: "三食堂",
                coordinate: CampusCoordinate(latitude: 32.2104, longitude: 118.7222)
            ),
            CampusStoreOption(
                id: northGateBreakfastID,
                campusId: campusId,
                name: "北门早餐铺",
                area: "北门生活区",
                coordinate: CampusCoordinate(latitude: 32.2132, longitude: 118.7177)
            ),
            CampusStoreOption(
                id: eastGardenLightMealID,
                campusId: campusId,
                name: "东苑轻食店",
                area: "东苑",
                coordinate: CampusCoordinate(latitude: 32.2037, longitude: 118.7268)
            ),
            CampusStoreOption(
                id: westGardenMalaTangID,
                campusId: campusId,
                name: "西苑麻辣烫",
                area: "西苑",
                coordinate: CampusCoordinate(latitude: 32.2020, longitude: 118.7116)
            )
        ]

        dishesByStoreID = [
            firstCanteenNoodleID: [
                CampusDishOption(
                    id: UUID(uuidString: "0E26DC19-D72D-4FA2-BA72-77AE0BFFFD19")!,
                    storeId: firstCanteenNoodleID,
                    name: "番茄牛肉米线",
                    price: 15,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 620,
                        proteinG: 28,
                        fatG: 18,
                        carbG: 86,
                        sodiumMg: 1480,
                        fiberG: 5
                    )
                ),
                CampusDishOption(
                    id: UUID(uuidString: "6B89AD8C-DCCB-4708-8F6D-A6A3FA2FB6F0")!,
                    storeId: firstCanteenNoodleID,
                    name: "酸辣鸡丝米线",
                    price: 13,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 560,
                        proteinG: 23,
                        fatG: 15,
                        carbG: 81,
                        sodiumMg: 1360,
                        fiberG: 4
                    )
                )
            ],
            secondCanteenRiceID: [
                CampusDishOption(
                    id: UUID(uuidString: "887C7965-A30D-4F56-90AD-E93FDBA43276")!,
                    storeId: secondCanteenRiceID,
                    name: "黑椒鸡腿饭",
                    price: 18,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 760,
                        proteinG: 34,
                        fatG: 24,
                        carbG: 98,
                        sodiumMg: 1620,
                        fiberG: 6
                    )
                ),
                CampusDishOption(
                    id: UUID(uuidString: "4C5B8474-B6F3-4D68-81F0-03F6A1A4D9A9")!,
                    storeId: secondCanteenRiceID,
                    name: "鱼香肉丝饭",
                    price: 16,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 705,
                        proteinG: 27,
                        fatG: 22,
                        carbG: 95,
                        sodiumMg: 1710,
                        fiberG: 4
                    )
                )
            ],
            halalWindowID: [
                CampusDishOption(
                    id: UUID(uuidString: "A176EA02-C0E2-4E28-8D95-E8B5E7D3715A")!,
                    storeId: halalWindowID,
                    name: "兰州牛肉面",
                    price: 14,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 590,
                        proteinG: 30,
                        fatG: 14,
                        carbG: 86,
                        sodiumMg: 1390,
                        fiberG: 3
                    )
                ),
                CampusDishOption(
                    id: UUID(uuidString: "32A76970-8B3E-48AA-87A7-D4AD344D3D7E")!,
                    storeId: halalWindowID,
                    name: "孜然羊肉盖饭",
                    price: 19,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 810,
                        proteinG: 33,
                        fatG: 29,
                        carbG: 101,
                        sodiumMg: 1730,
                        fiberG: 5
                    )
                )
            ],
            northGateBreakfastID: [
                CampusDishOption(
                    id: UUID(uuidString: "227480D9-E895-4398-9A56-0FC57A31B3D3")!,
                    storeId: northGateBreakfastID,
                    name: "豆浆 + 鸡蛋灌饼",
                    price: 9,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 455,
                        proteinG: 17,
                        fatG: 14,
                        carbG: 63,
                        sodiumMg: 780,
                        fiberG: 3
                    )
                ),
                CampusDishOption(
                    id: UUID(uuidString: "E5995666-225D-4518-B2A6-AC9924A1A4CB")!,
                    storeId: northGateBreakfastID,
                    name: "小米粥 + 肉包",
                    price: 8,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 390,
                        proteinG: 13,
                        fatG: 9,
                        carbG: 61,
                        sodiumMg: 640,
                        fiberG: 2
                    )
                )
            ],
            eastGardenLightMealID: [
                CampusDishOption(
                    id: UUID(uuidString: "43DD9A6C-189A-4DF4-BFB2-C66CB0C1E7B4")!,
                    storeId: eastGardenLightMealID,
                    name: "鸡胸肉沙拉碗",
                    price: 22,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 430,
                        proteinG: 37,
                        fatG: 17,
                        carbG: 29,
                        sodiumMg: 920,
                        fiberG: 8
                    )
                ),
                CampusDishOption(
                    id: UUID(uuidString: "6E52ED47-FCB5-4AB8-8FBF-EE6C5A63A071")!,
                    storeId: eastGardenLightMealID,
                    name: "全麦鸡肉卷",
                    price: 18,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 480,
                        proteinG: 29,
                        fatG: 16,
                        carbG: 51,
                        sodiumMg: 1100,
                        fiberG: 6
                    )
                )
            ],
            westGardenMalaTangID: [
                CampusDishOption(
                    id: UUID(uuidString: "98A76128-0E13-4261-8AC3-A2EA8B389455")!,
                    storeId: westGardenMalaTangID,
                    name: "微辣麻辣烫",
                    price: 17,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 650,
                        proteinG: 26,
                        fatG: 21,
                        carbG: 82,
                        sodiumMg: 1980,
                        fiberG: 7
                    )
                ),
                CampusDishOption(
                    id: UUID(uuidString: "D8A6D791-DCAF-4A60-8D54-4D5A4ECBD333")!,
                    storeId: westGardenMalaTangID,
                    name: "番茄汤麻辣烫",
                    price: 18,
                    nutrition: NutrientSnapshot(
                        caloriesKcal: 610,
                        proteinG: 25,
                        fatG: 18,
                        carbG: 79,
                        sodiumMg: 1760,
                        fiberG: 7
                    )
                )
            ]
        ]
    }

    public func fetchStores(campusId: String) async throws -> [CampusStoreOption] {
        guard campusId == self.campusId else {
            throw CampusMenuDomainError.unsupportedCampus
        }
        return stores
    }

    public func fetchDishes(storeId: UUID) async throws -> [CampusDishOption] {
        guard let dishes = dishesByStoreID[storeId] else {
            throw CampusMenuDomainError.storeNotFound
        }
        return dishes
    }
}
