import Foundation
import CoreDomain

public actor InMemoryMealLogRepository: MealLogRepository {
    private var mealLogs: [MealLog]

    public init(seedMealLogs: [MealLog]? = nil) {
        let initialLogs = seedMealLogs ?? InMemoryMealLogRepository.defaultSeedData()
        self.mealLogs = initialLogs.sorted { $0.date > $1.date }
    }

    public func fetchMealLogs() async throws -> [MealLog] {
        mealLogs.sorted { $0.date > $1.date }
    }

    public func createMealLog(input: NewMealLogInput) async throws -> MealLog {
        let log = MealLog(
            id: UUID(),
            date: input.date,
            mealType: input.mealType,
            storeName: input.storeName,
            dishName: input.dishName,
            price: input.price
        )
        mealLogs.insert(log, at: 0)
        mealLogs.sort { $0.date > $1.date }
        return log
    }

    public func updateMealLog(id: MealLog.ID, input: NewMealLogInput) async throws -> MealLog {
        guard let index = mealLogs.firstIndex(where: { $0.id == id }) else {
            throw MealLogDomainError.notFound
        }

        let updated = MealLog(
            id: id,
            date: input.date,
            mealType: input.mealType,
            storeName: input.storeName,
            dishName: input.dishName,
            price: input.price
        )
        mealLogs[index] = updated
        mealLogs.sort { $0.date > $1.date }
        return updated
    }

    public func deleteMealLog(id: MealLog.ID) async throws {
        guard let index = mealLogs.firstIndex(where: { $0.id == id }) else {
            throw MealLogDomainError.notFound
        }
        mealLogs.remove(at: index)
    }

    nonisolated private static func defaultSeedData() -> [MealLog] {
        let calendar = Calendar.current
        let now = Date()

        return [
            MealLog(
                id: UUID(),
                date: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                mealType: .lunch,
                storeName: "一食堂 · 米线档",
                dishName: "番茄牛肉米线",
                price: 15
            ),
            MealLog(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                mealType: .dinner,
                storeName: "二食堂 · 盖浇饭",
                dishName: "黑椒鸡腿饭",
                price: 18
            ),
            MealLog(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                mealType: .breakfast,
                storeName: "北门早餐铺",
                dishName: "豆浆 + 鸡蛋灌饼",
                price: 9
            )
        ]
    }
}
