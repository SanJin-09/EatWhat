import Foundation

public protocol MealLogRepository: Sendable {
    func fetchMealLogs() async throws -> [MealLog]
    func createMealLog(input: NewMealLogInput) async throws -> MealLog
    func updateMealLog(id: MealLog.ID, input: NewMealLogInput) async throws -> MealLog
    func deleteMealLog(id: MealLog.ID) async throws
}
