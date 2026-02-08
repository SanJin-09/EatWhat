import Testing
import Foundation
import CoreDomain
@testable import FeatureRecommendation

@Test
func moduleNameNotEmpty() {
    #expect(!FeatureRecommendationModule.name.isEmpty)
}

@Test
func recommendMostFrequentLunchFromHistory() {
    let now = Date()
    let calendar = Calendar.current
    let engine = FrequencyBasedRecommendationEngine(lookbackDays: 30, calendar: calendar)
    let logs = [
        MealLog(
            id: UUID(),
            date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            mealType: .lunch,
            storeName: "二食堂盖浇饭",
            dishName: "黑椒鸡腿饭",
            price: 18
        ),
        MealLog(
            id: UUID(),
            date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
            mealType: .lunch,
            storeName: "二食堂盖浇饭",
            dishName: "黑椒鸡腿饭",
            price: 18
        ),
        MealLog(
            id: UUID(),
            date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            mealType: .lunch,
            storeName: "一食堂面档",
            dishName: "牛肉拉面",
            price: 16
        )
    ]

    let recommendation = engine.makeRecommendations(from: logs, now: now)
    let lunch = recommendation.meals.first(where: { $0.mealType == .lunch })
    #expect(lunch?.dishName == "黑椒鸡腿饭")
    #expect(lunch?.source == .history)
}

@Test
func useFallbackWhenNoBreakfastHistory() {
    let now = Date()
    let engine = FrequencyBasedRecommendationEngine(lookbackDays: 30)
    let logs = [
        MealLog(
            id: UUID(),
            date: now,
            mealType: .lunch,
            storeName: "一食堂快餐",
            dishName: "香菇鸡腿饭",
            price: 15
        )
    ]

    let recommendation = engine.makeRecommendations(from: logs, now: now)
    let breakfast = recommendation.meals.first(where: { $0.mealType == .breakfast })
    #expect(breakfast?.source == .fallback)
}
