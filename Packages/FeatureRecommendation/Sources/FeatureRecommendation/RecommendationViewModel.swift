#if os(iOS)
import Combine
import Foundation
import CoreDomain

@MainActor
public final class RecommendationViewModel: ObservableObject {
    @Published public private(set) var recommendation: DailyRecommendation?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let getMealLogsUseCase: any GetMealLogsUseCaseProtocol
    private let recommendationEngine: any RecommendationEngineProtocol

    public init(
        getMealLogsUseCase: any GetMealLogsUseCaseProtocol,
        recommendationEngine: any RecommendationEngineProtocol = FrequencyBasedRecommendationEngine()
    ) {
        self.getMealLogsUseCase = getMealLogsUseCase
        self.recommendationEngine = recommendationEngine
    }

    public var recommendedMeals: [RecommendedMeal] {
        recommendation?.meals ?? []
    }

    public var logCount: Int {
        recommendation?.logCount ?? 0
    }

    public var isColdStart: Bool {
        logCount < 9
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let logs = try await getMealLogsUseCase.execute()
            recommendation = recommendationEngine.makeRecommendations(from: logs, now: Date())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func clearError() {
        errorMessage = nil
    }
}
#endif
