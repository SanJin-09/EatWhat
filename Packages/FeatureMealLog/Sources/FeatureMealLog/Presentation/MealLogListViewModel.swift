import Combine
import Foundation
import CoreDomain

@MainActor
public final class MealLogListViewModel: ObservableObject {
    @Published public private(set) var mealLogs: [MealLog] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let getMealLogsUseCase: any GetMealLogsUseCaseProtocol
    private let createMealLogUseCase: any CreateMealLogUseCaseProtocol
    private let updateMealLogUseCase: any UpdateMealLogUseCaseProtocol
    private let deleteMealLogUseCase: any DeleteMealLogUseCaseProtocol

    public init(
        getMealLogsUseCase: any GetMealLogsUseCaseProtocol,
        createMealLogUseCase: any CreateMealLogUseCaseProtocol,
        updateMealLogUseCase: any UpdateMealLogUseCaseProtocol,
        deleteMealLogUseCase: any DeleteMealLogUseCaseProtocol
    ) {
        self.getMealLogsUseCase = getMealLogsUseCase
        self.createMealLogUseCase = createMealLogUseCase
        self.updateMealLogUseCase = updateMealLogUseCase
        self.deleteMealLogUseCase = deleteMealLogUseCase
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            mealLogs = try await getMealLogsUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    public func addLog(input: NewMealLogInput) async -> Bool {
        do {
            let created = try await createMealLogUseCase.execute(input)
            mealLogs.insert(created, at: 0)
            mealLogs.sort { $0.date > $1.date }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    public func deleteLogs(at offsets: IndexSet) async {
        let ids = offsets.compactMap { index -> MealLog.ID? in
            guard mealLogs.indices.contains(index) else { return nil }
            return mealLogs[index].id
        }

        guard !ids.isEmpty else { return }

        do {
            for id in ids {
                try await deleteMealLogUseCase.execute(id: id)
            }
            mealLogs.remove(atOffsets: offsets)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    public func updateLog(id: MealLog.ID, input: NewMealLogInput) async -> Bool {
        do {
            let updated = try await updateMealLogUseCase.execute(id: id, input: input)
            guard let index = mealLogs.firstIndex(where: { $0.id == id }) else {
                await load()
                return true
            }
            mealLogs[index] = updated
            mealLogs.sort { $0.date > $1.date }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    public func clearError() {
        errorMessage = nil
    }
}
