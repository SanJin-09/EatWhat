import Foundation
import CoreDomain

public enum CampusMenuAPIContract {
    public static let storesPathTemplate = "/campuses/{campusId}/stores"
    public static let dishesPathTemplate = "/stores/{storeId}/dishes"
    public static let createMealLogPath = "/meal-logs"
}

public struct CampusStoreDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let area: String
    public let latitude: Double
    public let longitude: Double

    public init(
        id: UUID,
        name: String,
        area: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.area = area
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct CampusDishDTO: Codable, Sendable {
    public let id: UUID
    public let storeId: UUID
    public let name: String
    public let price: Double?
    public let nutrition: NutritionDTO?

    public init(
        id: UUID,
        storeId: UUID,
        name: String,
        price: Double?,
        nutrition: NutritionDTO?
    ) {
        self.id = id
        self.storeId = storeId
        self.name = name
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
