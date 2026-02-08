import Foundation
import CoreDomain
import FeatureCampusStore
import FeatureMealLog
import FeatureRecommendation

/// Central place to build and provide app-level dependencies.
final class DependencyContainer {
    let createdAt: Date
    private let mealLogRepository: any MealLogRepository

    init(
        createdAt: Date = Date(),
        mealLogRepository: (any MealLogRepository)? = nil
    ) {
        self.createdAt = createdAt
        if let mealLogRepository {
            self.mealLogRepository = mealLogRepository
            return
        }

        do {
            self.mealLogRepository = try SwiftDataMealLogRepository.makeDefaultRepository()
        } catch {
            assertionFailure("SwiftData init failed. Fallback to in-memory repository.")
            self.mealLogRepository = InMemoryMealLogRepository()
        }
    }

    @MainActor
    func makeMealLogListViewModel() -> MealLogListViewModel {
        MealLogListViewModel(
            getMealLogsUseCase: GetMealLogsUseCase(repository: mealLogRepository),
            createMealLogUseCase: CreateMealLogUseCase(repository: mealLogRepository),
            updateMealLogUseCase: UpdateMealLogUseCase(repository: mealLogRepository),
            deleteMealLogUseCase: DeleteMealLogUseCase(repository: mealLogRepository)
        )
    }

    @MainActor
    func makeRecommendationViewModel() -> RecommendationViewModel {
        RecommendationViewModel(
            getMealLogsUseCase: GetMealLogsUseCase(repository: mealLogRepository)
        )
    }

    @MainActor
    func makeCampusStoreMapViewModel() -> CampusStoreMapViewModel {
        CampusStoreMapViewModel()
    }
}
