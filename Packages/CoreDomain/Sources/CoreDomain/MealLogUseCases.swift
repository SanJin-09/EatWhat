import Foundation

public protocol GetMealLogsUseCaseProtocol: Sendable {
    func execute() async throws -> [MealLog]
}

public protocol CreateMealLogUseCaseProtocol: Sendable {
    func execute(_ input: NewMealLogInput) async throws -> MealLog
}

public protocol DeleteMealLogUseCaseProtocol: Sendable {
    func execute(id: MealLog.ID) async throws
}

public protocol UpdateMealLogUseCaseProtocol: Sendable {
    func execute(id: MealLog.ID, input: NewMealLogInput) async throws -> MealLog
}

public struct GetMealLogsUseCase: GetMealLogsUseCaseProtocol {
    private let repository: any MealLogRepository

    public init(repository: any MealLogRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [MealLog] {
        try await repository.fetchMealLogs().sorted { $0.date > $1.date }
    }
}

public struct CreateMealLogUseCase: CreateMealLogUseCaseProtocol {
    private let repository: any MealLogRepository

    public init(repository: any MealLogRepository) {
        self.repository = repository
    }

    public func execute(_ input: NewMealLogInput) async throws -> MealLog {
        try await repository.createMealLog(input: normalized(input))
    }
}

public struct DeleteMealLogUseCase: DeleteMealLogUseCaseProtocol {
    private let repository: any MealLogRepository

    public init(repository: any MealLogRepository) {
        self.repository = repository
    }

    public func execute(id: MealLog.ID) async throws {
        try await repository.deleteMealLog(id: id)
    }
}

public struct UpdateMealLogUseCase: UpdateMealLogUseCaseProtocol {
    private let repository: any MealLogRepository

    public init(repository: any MealLogRepository) {
        self.repository = repository
    }

    public func execute(id: MealLog.ID, input: NewMealLogInput) async throws -> MealLog {
        try await repository.updateMealLog(id: id, input: normalized(input))
    }
}

private func normalized(_ input: NewMealLogInput) throws -> NewMealLogInput {
    let storeName = input.storeName.trimmingCharacters(in: .whitespacesAndNewlines)
    let dishName = input.dishName.trimmingCharacters(in: .whitespacesAndNewlines)

    if storeName.isEmpty || dishName.isEmpty {
        throw MealLogDomainError.invalidInput
    }

    if let price = input.price, price < 0 {
        throw MealLogDomainError.invalidInput
    }

    return NewMealLogInput(
        date: input.date,
        mealType: input.mealType,
        storeName: storeName,
        dishName: dishName,
        price: input.price
    )
}
