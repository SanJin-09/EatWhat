import Foundation

public struct CampusCoordinate: Equatable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct CampusStoreOption: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let campusId: String
    public let name: String
    public let area: String
    public let coordinate: CampusCoordinate

    public init(
        id: UUID,
        campusId: String,
        name: String,
        area: String,
        coordinate: CampusCoordinate
    ) {
        self.id = id
        self.campusId = campusId
        self.name = name
        self.area = area
        self.coordinate = coordinate
    }
}

public struct CampusCanteenFloorOption: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let floorOrder: Int
    public let floorLabel: String
    public let stores: [CampusStoreOption]

    public init(
        id: UUID,
        floorOrder: Int,
        floorLabel: String,
        stores: [CampusStoreOption]
    ) {
        self.id = id
        self.floorOrder = floorOrder
        self.floorLabel = floorLabel
        self.stores = stores
    }
}

public struct CampusCanteenOption: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let campusId: String
    public let name: String
    public let coordinate: CampusCoordinate?
    public let floors: [CampusCanteenFloorOption]

    public init(
        id: UUID,
        campusId: String,
        name: String,
        coordinate: CampusCoordinate?,
        floors: [CampusCanteenFloorOption]
    ) {
        self.id = id
        self.campusId = campusId
        self.name = name
        self.coordinate = coordinate
        self.floors = floors
    }
}

public struct CampusStoreHierarchyOption: Equatable, Codable, Sendable {
    public let canteens: [CampusCanteenOption]
    public let outdoorStores: [CampusStoreOption]

    public init(
        canteens: [CampusCanteenOption],
        outdoorStores: [CampusStoreOption]
    ) {
        self.canteens = canteens
        self.outdoorStores = outdoorStores
    }

    public var flattenedStores: [CampusStoreOption] {
        canteens.flatMap { canteen in
            canteen.floors.flatMap(\.stores)
        } + outdoorStores
    }
}

public struct CampusDishOption: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let storeId: UUID
    public let name: String
    public let price: Double?
    public let nutrition: NutrientSnapshot?

    public init(
        id: UUID,
        storeId: UUID,
        name: String,
        price: Double?,
        nutrition: NutrientSnapshot?
    ) {
        self.id = id
        self.storeId = storeId
        self.name = name
        self.price = price
        self.nutrition = nutrition
    }
}

public enum CampusMenuDomainError: Error, LocalizedError, Equatable {
    case storeNotFound
    case dishNotFound
    case unsupportedCampus

    public var errorDescription: String? {
        switch self {
        case .storeNotFound:
            return "未找到对应店铺。"
        case .dishNotFound:
            return "未找到对应菜品。"
        case .unsupportedCampus:
            return "当前校区暂不支持菜单数据。"
        }
    }
}

public protocol CampusMenuRepository: Sendable {
    func fetchStoreHierarchy(campusId: String) async throws -> CampusStoreHierarchyOption
    func fetchStores(campusId: String) async throws -> [CampusStoreOption]
    func fetchDishes(storeId: UUID) async throws -> [CampusDishOption]
}
