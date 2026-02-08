import Testing
@testable import FeatureMealLog
@testable import CoreDomain

@Test
func moduleNameNotEmpty() {
    #expect(!FeatureMealLogModule.name.isEmpty)
}

@Test
@MainActor
func nearestStoreFollowsMapCenterAfterDebounce() async throws {
    let viewModel = AddMealLogDraftViewModel(menuRepository: MockCampusMenuRepository())
    await viewModel.load()

    viewModel.updateMapCenter(CampusCoordinate(latitude: 32.2132, longitude: 118.7177))
    try await Task.sleep(nanoseconds: 450_000_000)

    #expect(viewModel.selectedStore?.name == "北门早餐铺")
}

@Test
@MainActor
func selectingStoreRefreshesDishesAndAutoFillsPriceAndNutrition() async throws {
    let viewModel = AddMealLogDraftViewModel(menuRepository: MockCampusMenuRepository())
    await viewModel.load()

    let targetStore = try #require(viewModel.stores.first(where: { $0.name == "一食堂米线档" }))
    viewModel.selectStoreManually(id: targetStore.id)
    try await waitUntilDishesLoaded(viewModel)

    let firstDish = try #require(viewModel.dishes.first)
    #expect(viewModel.dishSelection == .preset(firstDish.id))
    #expect(viewModel.priceText == "15")
    #expect(viewModel.selectedNutrition == firstDish.nutrition)
}

@Test
@MainActor
func customDishKeepsSnapshotAndClearsDishIDAndNutrition() async throws {
    let viewModel = AddMealLogDraftViewModel(menuRepository: MockCampusMenuRepository())
    await viewModel.load()

    let targetStore = try #require(viewModel.stores.first(where: { $0.name == "北门早餐铺" }))
    viewModel.selectStoreManually(id: targetStore.id)
    try await waitUntilDishesLoaded(viewModel)

    viewModel.setDishSelection(.custom)
    viewModel.customDishName = "手工燕麦杯"
    viewModel.priceText = "12"

    let input = try viewModel.makeInput(date: Date(), mealType: .breakfast)

    #expect(input.storeId == targetStore.id)
    #expect(input.dishId == nil)
    #expect(input.dishName == "手工燕麦杯")
    #expect(input.price == 12)
    #expect(input.nutrition == nil)
}

@MainActor
private func waitUntilDishesLoaded(_ viewModel: AddMealLogDraftViewModel) async throws {
    for _ in 0..<20 {
        if !viewModel.isLoadingDishes, !viewModel.dishes.isEmpty {
            return
        }
        try await Task.sleep(nanoseconds: 25_000_000)
    }
    throw TestTimeoutError.waitingForDishes
}

private enum TestTimeoutError: Error {
    case waitingForDishes
}
