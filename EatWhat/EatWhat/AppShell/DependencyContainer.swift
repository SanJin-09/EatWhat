import Foundation
import CoreDomain
import CoreNetworking
import FeatureCampusStore
import FeatureMealLog
import FeatureRecommendation

/// Central place to build and provide app-level dependencies.
final class DependencyContainer {
    let createdAt: Date
    private let mealLogRepository: any MealLogRepository
    private let campusMenuRepository: any CampusMenuRepository

    init(
        createdAt: Date = Date(),
        mealLogRepository: (any MealLogRepository)? = nil,
        campusMenuRepository: (any CampusMenuRepository)? = nil
    ) {
        self.createdAt = createdAt
        if let mealLogRepository {
            self.mealLogRepository = mealLogRepository
        } else {
            do {
                self.mealLogRepository = try SwiftDataMealLogRepository.makeDefaultRepository()
            } catch {
                assertionFailure("SwiftData init failed. Fallback to in-memory repository.")
                self.mealLogRepository = InMemoryMealLogRepository()
            }
        }

        if let campusMenuRepository {
            self.campusMenuRepository = campusMenuRepository
        } else {
            self.campusMenuRepository = Self.makeDefaultCampusMenuRepository()
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

    func makeCampusMenuRepository() -> any CampusMenuRepository {
        campusMenuRepository
    }

    @MainActor
    func makeCampusStoreMapViewModel() -> CampusStoreMapViewModel {
        CampusStoreMapViewModel()
    }
}

private extension DependencyContainer {
    static func makeDefaultCampusMenuRepository() -> any CampusMenuRepository {
        guard let baseURL = campusMenuBaseURLFromInfoPlist() else {
            return MockCampusMenuRepository()
        }

        return RemoteCampusMenuRepository(baseURL: baseURL)
    }

    static func campusMenuBaseURLFromInfoPlist() -> URL? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "CampusMenuAPIBaseURL") as? String
        else {
            return nil
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        // Keep mock repository when build setting is unresolved placeholder.
        guard !trimmed.contains("$(") else {
            return nil
        }

        return URL(string: trimmed)
    }
}
