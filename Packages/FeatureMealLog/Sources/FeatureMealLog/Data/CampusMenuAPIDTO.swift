import Foundation
import CoreDomain

public enum CampusMenuAPIContract {
    public static let storesPathTemplate = "/campuses/{campusId}/stores"
    public static let dishesPathTemplate = "/stores/{storeId}/dishes"
    public static let createMealLogPath = "/meal-logs"
}

public enum StoreLocationTypeDTO: String, Codable, Sendable {
    case canteen = "CANTEEN"
    case outdoor = "OUTDOOR"
}

public struct CampusStoreDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let area: String
    public let locationType: StoreLocationTypeDTO
    public let canteenId: UUID?
    public let canteenName: String?
    public let floorId: UUID?
    public let floorOrder: Int?
    public let floorLabel: String?
    public let latitude: Double
    public let longitude: Double

    public init(
        id: UUID,
        name: String,
        area: String,
        locationType: StoreLocationTypeDTO = .outdoor,
        canteenId: UUID? = nil,
        canteenName: String? = nil,
        floorId: UUID? = nil,
        floorOrder: Int? = nil,
        floorLabel: String? = nil,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.area = area
        self.locationType = locationType
        self.canteenId = canteenId
        self.canteenName = canteenName
        self.floorId = floorId
        self.floorOrder = floorOrder
        self.floorLabel = floorLabel
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct CanteenFloorDTO: Codable, Sendable {
    public let id: UUID
    public let floorOrder: Int
    public let floorLabel: String
    public let stores: [CampusStoreDTO]

    public init(
        id: UUID,
        floorOrder: Int,
        floorLabel: String,
        stores: [CampusStoreDTO]
    ) {
        self.id = id
        self.floorOrder = floorOrder
        self.floorLabel = floorLabel
        self.stores = stores
    }
}

public struct CampusCanteenDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let latitude: Double?
    public let longitude: Double?
    public let floors: [CanteenFloorDTO]

    public init(
        id: UUID,
        name: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        floors: [CanteenFloorDTO]
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.floors = floors
    }
}

public struct CampusStoreHierarchyEnvelopeDTO: Codable, Sendable {
    public let canteens: [CampusCanteenDTO]
    public let outdoorStores: [CampusStoreDTO]

    public init(
        canteens: [CampusCanteenDTO],
        outdoorStores: [CampusStoreDTO]
    ) {
        self.canteens = canteens
        self.outdoorStores = outdoorStores
    }
}

public struct CampusDishDTO: Codable, Sendable {
    public let id: UUID
    public let storeId: UUID
    public let name: String
    public let imageUrl: String?
    public let price: Double?
    public let nutrition: NutritionDTO?

    public init(
        id: UUID,
        storeId: UUID,
        name: String,
        imageUrl: String?,
        price: Double?,
        nutrition: NutritionDTO?
    ) {
        self.id = id
        self.storeId = storeId
        self.name = name
        self.imageUrl = imageUrl
        self.price = price
        self.nutrition = nutrition
    }
}

public struct NutritionDTO: Codable, Sendable {
    public let caloriesKcal: Double
    public let proteinG: Double
    public let fatG: Double
    public let carbG: Double
    public let sodiumMg: Double
    public let fiberG: Double

    public init(
        caloriesKcal: Double,
        proteinG: Double,
        fatG: Double,
        carbG: Double,
        sodiumMg: Double,
        fiberG: Double
    ) {
        self.caloriesKcal = caloriesKcal
        self.proteinG = proteinG
        self.fatG = fatG
        self.carbG = carbG
        self.sodiumMg = sodiumMg
        self.fiberG = fiberG
    }
}

public extension CampusStoreDTO {
    func toDomain(campusId: String) -> CampusStoreOption {
        CampusStoreOption(
            id: id,
            campusId: campusId,
            name: name,
            area: area,
            coordinate: CampusCoordinate(latitude: latitude, longitude: longitude)
        )
    }
}

public extension CampusStoreHierarchyEnvelopeDTO {
    func toDomain(campusId: String) -> CampusStoreHierarchyOption {
        let canteenOptions = canteens.map { canteen in
            CampusCanteenOption(
                id: canteen.id,
                campusId: campusId,
                name: canteen.name,
                coordinate: {
                    guard let latitude = canteen.latitude, let longitude = canteen.longitude else {
                        return nil
                    }
                    return CampusCoordinate(latitude: latitude, longitude: longitude)
                }(),
                floors: canteen.floors.map { floor in
                    CampusCanteenFloorOption(
                        id: floor.id,
                        floorOrder: floor.floorOrder,
                        floorLabel: floor.floorLabel,
                        stores: floor.stores.map { $0.toDomain(campusId: campusId) }
                    )
                }
            )
        }

        return CampusStoreHierarchyOption(
            canteens: canteenOptions,
            outdoorStores: outdoorStores.map { $0.toDomain(campusId: campusId) }
        )
    }

    var flattenedStores: [CampusStoreDTO] {
        let canteenStores = canteens.flatMap { canteen in
            canteen.floors.flatMap { floor in
                floor.stores.map { store in
                    CampusStoreDTO(
                        id: store.id,
                        name: store.name,
                        area: store.area,
                        locationType: .canteen,
                        canteenId: store.canteenId ?? canteen.id,
                        canteenName: store.canteenName ?? canteen.name,
                        floorId: store.floorId ?? floor.id,
                        floorOrder: store.floorOrder ?? floor.floorOrder,
                        floorLabel: store.floorLabel ?? floor.floorLabel,
                        latitude: store.latitude,
                        longitude: store.longitude
                    )
                }
            }
        }

        let normalizedOutdoorStores = outdoorStores.map { store in
            CampusStoreDTO(
                id: store.id,
                name: store.name,
                area: store.area,
                locationType: .outdoor,
                canteenId: nil,
                canteenName: nil,
                floorId: nil,
                floorOrder: nil,
                floorLabel: nil,
                latitude: store.latitude,
                longitude: store.longitude
            )
        }

        return canteenStores + normalizedOutdoorStores
    }
}

public extension CampusDishDTO {
    func toDomain() -> CampusDishOption {
        CampusDishOption(
            id: id,
            storeId: storeId,
            name: name,
            price: price,
            nutrition: nutrition?.toDomain()
        )
    }
}

public extension NutritionDTO {
    func toDomain() -> NutrientSnapshot {
        NutrientSnapshot(
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            fatG: fatG,
            carbG: carbG,
            sodiumMg: sodiumMg,
            fiberG: fiberG
        )
    }
}
