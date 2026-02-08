import Foundation

public enum MealType: String, CaseIterable, Codable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack

    public var displayName: String {
        switch self {
        case .breakfast:
            return "早餐"
        case .lunch:
            return "午餐"
        case .dinner:
            return "晚餐"
        case .snack:
            return "加餐"
        }
    }
}

public struct NutrientSnapshot: Equatable, Codable, Sendable {
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

    public var isValid: Bool {
        caloriesKcal >= 0 &&
            proteinG >= 0 &&
            fatG >= 0 &&
            carbG >= 0 &&
            sodiumMg >= 0 &&
            fiberG >= 0
    }
}

public struct MealLog: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let date: Date
    public let mealType: MealType
    public let storeId: UUID?
    public let dishId: UUID?
    public let storeName: String
    public let dishName: String
    public let price: Double?
    public let nutrition: NutrientSnapshot?

    public init(
        id: UUID,
        date: Date,
        mealType: MealType,
        storeId: UUID? = nil,
        dishId: UUID? = nil,
        storeName: String,
        dishName: String,
        price: Double?,
        nutrition: NutrientSnapshot? = nil
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.storeId = storeId
        self.dishId = dishId
        self.storeName = storeName
        self.dishName = dishName
        self.price = price
        self.nutrition = nutrition
    }
}

public struct NewMealLogInput: Equatable, Sendable {
    public let date: Date
    public let mealType: MealType
    public let storeId: UUID?
    public let dishId: UUID?
    public let storeName: String
    public let dishName: String
    public let price: Double?
    public let nutrition: NutrientSnapshot?

    public init(
        date: Date,
        mealType: MealType,
        storeId: UUID? = nil,
        dishId: UUID? = nil,
        storeName: String,
        dishName: String,
        price: Double?,
        nutrition: NutrientSnapshot? = nil
    ) {
        self.date = date
        self.mealType = mealType
        self.storeId = storeId
        self.dishId = dishId
        self.storeName = storeName
        self.dishName = dishName
        self.price = price
        self.nutrition = nutrition
    }
}

public enum MealLogDomainError: Error, LocalizedError, Equatable {
    case invalidInput
    case notFound

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "请输入完整且有效的饮食记录信息。"
        case .notFound:
            return "未找到对应的饮食记录。"
        }
    }
}
