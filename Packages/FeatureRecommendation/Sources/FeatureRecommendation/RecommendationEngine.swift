import Foundation
import CoreDomain

public struct RecommendedMeal: Identifiable, Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        case history
        case fallback
    }

    public var id: MealType { mealType }
    public let mealType: MealType
    public let storeName: String
    public let dishName: String
    public let estimatedPrice: Double?
    public let reason: String
    public let source: Source

    public init(
        mealType: MealType,
        storeName: String,
        dishName: String,
        estimatedPrice: Double?,
        reason: String,
        source: Source
    ) {
        self.mealType = mealType
        self.storeName = storeName
        self.dishName = dishName
        self.estimatedPrice = estimatedPrice
        self.reason = reason
        self.source = source
    }
}

public struct DailyRecommendation: Equatable, Sendable {
    public let generatedAt: Date
    public let logCount: Int
    public let meals: [RecommendedMeal]

    public init(generatedAt: Date, logCount: Int, meals: [RecommendedMeal]) {
        self.generatedAt = generatedAt
        self.logCount = logCount
        self.meals = meals
    }
}

public protocol RecommendationEngineProtocol: Sendable {
    func makeRecommendations(from logs: [MealLog], now: Date) -> DailyRecommendation
}

public struct FrequencyBasedRecommendationEngine: RecommendationEngineProtocol {
    private struct Aggregate {
        var count: Int
        var latestDate: Date
        var priceTotal: Double
        var priceCount: Int
        let storeName: String
        let dishName: String
    }

    private static let mealOrder: [MealType] = [.breakfast, .lunch, .dinner]

    private static let fallbackMeals: [MealType: [(storeName: String, dishName: String, price: Double?)]] = [
        .breakfast: [
            ("北门早餐铺", "豆浆 + 鸡蛋灌饼", 9),
            ("一食堂早餐档", "皮蛋瘦肉粥 + 包子", 8)
        ],
        .lunch: [
            ("一食堂快餐", "番茄牛肉米线", 15),
            ("二食堂盖浇饭", "黑椒鸡腿饭", 18)
        ],
        .dinner: [
            ("二食堂小炒", "青椒肉丝套餐", 16),
            ("东门轻食店", "鸡胸肉沙拉碗", 19)
        ]
    ]

    private let lookbackDays: Int
    private let calendar: Calendar

    public init(
        lookbackDays: Int = 30,
        calendar: Calendar = .current
    ) {
        self.lookbackDays = max(1, lookbackDays)
        self.calendar = calendar
    }

    public func makeRecommendations(from logs: [MealLog], now: Date = Date()) -> DailyRecommendation {
        let recentThreshold = calendar.date(byAdding: .day, value: -lookbackDays, to: now) ?? now
        let candidateLogs = logs.filter { $0.date >= recentThreshold }
        let meals = Self.mealOrder.map { recommend(for: $0, from: candidateLogs, now: now) }
        return DailyRecommendation(generatedAt: now, logCount: logs.count, meals: meals)
    }

    private func recommend(for mealType: MealType, from logs: [MealLog], now: Date) -> RecommendedMeal {
        let logsByMealType = logs.filter { $0.mealType == mealType }
        guard !logsByMealType.isEmpty else {
            return fallbackRecommendation(for: mealType)
        }

        var aggregates: [String: Aggregate] = [:]
        for log in logsByMealType {
            let key = "\(log.storeName)|\(log.dishName)"
            if var existing = aggregates[key] {
                existing.count += 1
                if log.date > existing.latestDate {
                    existing.latestDate = log.date
                }
                if let price = log.price {
                    existing.priceTotal += price
                    existing.priceCount += 1
                }
                aggregates[key] = existing
            } else {
                aggregates[key] = Aggregate(
                    count: 1,
                    latestDate: log.date,
                    priceTotal: log.price ?? 0,
                    priceCount: log.price == nil ? 0 : 1,
                    storeName: log.storeName,
                    dishName: log.dishName
                )
            }
        }

        let best = aggregates.values.max { left, right in
            let leftScore = score(left, now: now)
            let rightScore = score(right, now: now)
            if leftScore == rightScore {
                if left.count == right.count {
                    return left.latestDate < right.latestDate
                }
                return left.count < right.count
            }
            return leftScore < rightScore
        }

        guard let best else {
            return fallbackRecommendation(for: mealType)
        }

        let estimatedPrice = best.priceCount == 0 ? nil : best.priceTotal / Double(best.priceCount)
        return RecommendedMeal(
            mealType: mealType,
            storeName: best.storeName,
            dishName: best.dishName,
            estimatedPrice: estimatedPrice,
            reason: historyReason(for: best, now: now),
            source: .history
        )
    }

    private func score(_ aggregate: Aggregate, now: Date) -> Double {
        let days = max(0, calendar.dateComponents([.day], from: aggregate.latestDate, to: now).day ?? lookbackDays)
        let recencyScore = max(0, Double(lookbackDays - days)) / Double(lookbackDays)
        return (Double(aggregate.count) * 2) + recencyScore
    }

    private func historyReason(for aggregate: Aggregate, now: Date) -> String {
        let days = max(0, calendar.dateComponents([.day], from: aggregate.latestDate, to: now).day ?? 0)
        return "最近\(lookbackDays)天记录\(aggregate.count)次，最近一次是\(days)天前。"
    }

    private func fallbackRecommendation(for mealType: MealType) -> RecommendedMeal {
        let fallback = Self.fallbackMeals[mealType]?.first ?? ("校内食堂", "今日特餐", nil)
        return RecommendedMeal(
            mealType: mealType,
            storeName: fallback.storeName,
            dishName: fallback.dishName,
            estimatedPrice: fallback.price,
            reason: "你的该餐次记录偏少，先给一个常见选择。",
            source: .fallback
        )
    }
}
