import Foundation
import SwiftData
import CoreDomain

@Model
final class MealLogEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mealTypeRawValue: String
    var storeId: UUID?
    var dishId: UUID?
    var storeName: String
    var dishName: String
    var price: Double?
    var caloriesKcal: Double?
    var proteinG: Double?
    var fatG: Double?
    var carbG: Double?
    var sodiumMg: Double?
    var fiberG: Double?

    init(
        id: UUID,
        date: Date,
        mealTypeRawValue: String,
        storeId: UUID?,
        dishId: UUID?,
        storeName: String,
        dishName: String,
        price: Double?,
        caloriesKcal: Double?,
        proteinG: Double?,
        fatG: Double?,
        carbG: Double?,
        sodiumMg: Double?,
        fiberG: Double?
    ) {
        self.id = id
        self.date = date
        self.mealTypeRawValue = mealTypeRawValue
        self.storeId = storeId
        self.dishId = dishId
        self.storeName = storeName
        self.dishName = dishName
        self.price = price
        self.caloriesKcal = caloriesKcal
        self.proteinG = proteinG
        self.fatG = fatG
        self.carbG = carbG
        self.sodiumMg = sodiumMg
        self.fiberG = fiberG
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
            storeId: input.storeId,
            dishId: input.dishId,
            storeName: input.storeName,
            dishName: input.dishName,
            price: input.price,
            caloriesKcal: input.nutrition?.caloriesKcal,
            proteinG: input.nutrition?.proteinG,
            fatG: input.nutrition?.fatG,
            carbG: input.nutrition?.carbG,
            sodiumMg: input.nutrition?.sodiumMg,
            fiberG: input.nutrition?.fiberG
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
        entity.storeId = input.storeId
        entity.dishId = input.dishId
        entity.storeName = input.storeName
        entity.dishName = input.dishName
        entity.price = input.price
        entity.caloriesKcal = input.nutrition?.caloriesKcal
        entity.proteinG = input.nutrition?.proteinG
        entity.fatG = input.nutrition?.fatG
        entity.carbG = input.nutrition?.carbG
        entity.sodiumMg = input.nutrition?.sodiumMg
        entity.fiberG = input.nutrition?.fiberG
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
        let nutrition: NutrientSnapshot?
        if let caloriesKcal = entity.caloriesKcal,
           let proteinG = entity.proteinG,
           let fatG = entity.fatG,
           let carbG = entity.carbG,
           let sodiumMg = entity.sodiumMg,
           let fiberG = entity.fiberG {
            nutrition = NutrientSnapshot(
                caloriesKcal: caloriesKcal,
                proteinG: proteinG,
                fatG: fatG,
                carbG: carbG,
                sodiumMg: sodiumMg,
                fiberG: fiberG
            )
        } else {
            nutrition = nil
        }

        return MealLog(
            id: entity.id,
            date: entity.date,
            mealType: MealType(rawValue: entity.mealTypeRawValue) ?? .lunch,
            storeId: entity.storeId,
            dishId: entity.dishId,
            storeName: entity.storeName,
            dishName: entity.dishName,
            price: entity.price,
            nutrition: nutrition
        )
    }
}
