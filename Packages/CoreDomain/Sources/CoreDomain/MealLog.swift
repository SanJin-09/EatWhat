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

public struct MealLog: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let date: Date
    public let mealType: MealType
    public let storeName: String
    public let dishName: String
    public let price: Double?

    public init(
        id: UUID,
        date: Date,
        mealType: MealType,
        storeName: String,
        dishName: String,
        price: Double?
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.storeName = storeName
        self.dishName = dishName
        self.price = price
    }
}

public struct NewMealLogInput: Equatable, Sendable {
    public let date: Date
    public let mealType: MealType
    public let storeName: String
    public let dishName: String
    public let price: Double?

    public init(
        date: Date,
        mealType: MealType,
        storeName: String,
        dishName: String,
        price: Double?
    ) {
        self.date = date
        self.mealType = mealType
        self.storeName = storeName
        self.dishName = dishName
        self.price = price
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
