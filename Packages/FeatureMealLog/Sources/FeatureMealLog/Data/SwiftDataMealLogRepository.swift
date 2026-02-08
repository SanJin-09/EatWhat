import Foundation
import SwiftData
import CoreDomain

@Model
final class MealLogEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mealTypeRawValue: String
    var storeName: String
    var dishName: String
    var price: Double?

    init(
        id: UUID,
        date: Date,
        mealTypeRawValue: String,
        storeName: String,
        dishName: String,
        price: Double?
    ) {
        self.id = id
        self.date = date
        self.mealTypeRawValue = mealTypeRawValue
        self.storeName = storeName
        self.dishName = dishName
        self.price = price
    }
}

public actor SwiftDataMealLogRepository: MealLogRepository {
    private let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public static func makeDefaultRepository(
        inMemoryOnly: Bool = false
    ) throws -> SwiftDataMealLogRepository {
        let schema = Schema([MealLogEntity.self])
        let configuration = ModelConfiguration(
            "EatWhatMealLog",
            schema: schema,
            isStoredInMemoryOnly: inMemoryOnly
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        return SwiftDataMealLogRepository(modelContainer: container)
    }

    public func fetchMealLogs() async throws -> [MealLog] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<MealLogEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map(Self.toDomain)
    }

    public func createMealLog(input: NewMealLogInput) async throws -> MealLog {
        let context = ModelContext(modelContainer)
        let entity = MealLogEntity(
            id: UUID(),
            date: input.date,
            mealTypeRawValue: input.mealType.rawValue,
            storeName: input.storeName,
            dishName: input.dishName,
            price: input.price
        )
        context.insert(entity)
        try context.save()
        return Self.toDomain(entity)
    }

    public func updateMealLog(id: MealLog.ID, input: NewMealLogInput) async throws -> MealLog {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<MealLogEntity> { $0.id == id }
        var descriptor = FetchDescriptor<MealLogEntity>(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let entity = try context.fetch(descriptor).first else {
            throw MealLogDomainError.notFound
        }

        entity.date = input.date
        entity.mealTypeRawValue = input.mealType.rawValue
        entity.storeName = input.storeName
        entity.dishName = input.dishName
        entity.price = input.price
        try context.save()
        return Self.toDomain(entity)
    }

    public func deleteMealLog(id: MealLog.ID) async throws {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<MealLogEntity> { $0.id == id }
        var descriptor = FetchDescriptor<MealLogEntity>(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let entity = try context.fetch(descriptor).first else {
            throw MealLogDomainError.notFound
        }

        context.delete(entity)
        try context.save()
    }

    private static func toDomain(_ entity: MealLogEntity) -> MealLog {
        MealLog(
            id: entity.id,
            date: entity.date,
            mealType: MealType(rawValue: entity.mealTypeRawValue) ?? .lunch,
            storeName: entity.storeName,
            dishName: entity.dishName,
            price: entity.price
        )
    }
}
