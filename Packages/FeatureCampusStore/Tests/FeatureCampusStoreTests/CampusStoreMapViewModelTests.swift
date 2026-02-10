import Foundation
import Testing
import CoreDomain
@testable import FeatureCampusStore

@Test
@MainActor
func loadHierarchyBuildsMarkersAndTracksHiddenCanteens() async throws {
    let storeID = UUID(uuidString: "023D4F10-FC27-4728-84D0-F6E9FD89EE57")!
    let hierarchy = makeHierarchy(
        includeCanteenCoordinate: true,
        includeSecondCanteenWithoutCoordinate: true,
        includeOutdoorStore: true,
        storeID: storeID
    )
    let repository = StubCampusMenuRepository(
        hierarchy: hierarchy,
        dishesByStoreID: [storeID: []],
        failuresRemainingByStore: [:]
    )

    let viewModel = CampusStoreMapViewModel(menuRepository: repository)
    await viewModel.loadStoresIfNeeded()

    #expect(viewModel.markers.count == 2)
    #expect(viewModel.hiddenCanteenCount == 1)
    #expect(viewModel.mapEmptyMessage == nil)

    let kinds = Set(viewModel.markers.map(\.kind))
    #expect(kinds.contains(.canteen))
    #expect(kinds.contains(.outdoorStore))
}

@Test
@MainActor
func loadHierarchyShowsEmptyPlaceholderWhenNoMarkerCanBeRendered() async throws {
    let hierarchy = makeHierarchy(
        includeCanteenCoordinate: false,
        includeSecondCanteenWithoutCoordinate: false,
        includeOutdoorStore: false,
        storeID: UUID(uuidString: "E4B16C93-F543-4B10-A4F1-B128AE5BF6D8")!
    )
    let repository = StubCampusMenuRepository(
        hierarchy: hierarchy,
        dishesByStoreID: [:],
        failuresRemainingByStore: [:]
    )

    let viewModel = CampusStoreMapViewModel(menuRepository: repository)
    await viewModel.loadStoresIfNeeded()

    #expect(viewModel.markers.isEmpty)
    #expect(viewModel.hiddenCanteenCount == 1)
    #expect(viewModel.mapEmptyMessage == "暂无可展示店铺/食堂点位。")
}

@Test
@MainActor
func loadDishesUsesCacheAfterFirstSuccessfulLoad() async throws {
    let storeID = UUID(uuidString: "4D30521A-D31B-4A5A-A5B7-5F0214AC8EE2")!
    let hierarchy = makeHierarchy(
        includeCanteenCoordinate: true,
        includeSecondCanteenWithoutCoordinate: false,
        includeOutdoorStore: true,
        storeID: storeID
    )
    let repository = StubCampusMenuRepository(
        hierarchy: hierarchy,
        dishesByStoreID: [storeID: [sampleDish(storeID: storeID)]],
        failuresRemainingByStore: [:]
    )

    let viewModel = CampusStoreMapViewModel(menuRepository: repository)
    await viewModel.loadStoresIfNeeded()
    await viewModel.loadDishesIfNeeded(storeId: storeID)
    await viewModel.loadDishesIfNeeded(storeId: storeID)

    #expect(loadedDishCount(from: viewModel.dishState(for: storeID)) == 1)
    #expect(await repository.dishFetchCount(for: storeID) == 1)
}

@Test
@MainActor
func retryDishesRecoversFromFailure() async throws {
    let storeID = UUID(uuidString: "43B286A0-207E-4E83-804C-6F00FF29A942")!
    let hierarchy = makeHierarchy(
        includeCanteenCoordinate: true,
        includeSecondCanteenWithoutCoordinate: false,
        includeOutdoorStore: true,
        storeID: storeID
    )
    let repository = StubCampusMenuRepository(
        hierarchy: hierarchy,
        dishesByStoreID: [storeID: [sampleDish(storeID: storeID)]],
        failuresRemainingByStore: [storeID: 1]
    )

    let viewModel = CampusStoreMapViewModel(menuRepository: repository)
    await viewModel.loadStoresIfNeeded()

    await viewModel.loadDishesIfNeeded(storeId: storeID)
    #expect(isFailed(viewModel.dishState(for: storeID)))

    await viewModel.retryDishes(for: storeID)
    #expect(loadedDishCount(from: viewModel.dishState(for: storeID)) == 1)
}

private func sampleDish(storeID: UUID) -> CampusDishOption {
    CampusDishOption(
        id: UUID(uuidString: "F1706BA8-A0D5-4C4C-8D4E-E42DE35C7104")!,
        storeId: storeID,
        name: "样例菜品",
        price: 12,
        nutrition: NutrientSnapshot(
            caloriesKcal: 450,
            proteinG: 18,
            fatG: 12,
            carbG: 58,
            sodiumMg: 850,
            fiberG: 3
        )
    )
}

private func makeHierarchy(
    includeCanteenCoordinate: Bool,
    includeSecondCanteenWithoutCoordinate: Bool,
    includeOutdoorStore: Bool,
    storeID: UUID
) -> CampusStoreHierarchyOption {
    let canteenStore = CampusStoreOption(
        id: UUID(uuidString: "F231F4CB-B5CF-4A5F-AEA0-E0E912FA4EC8")!,
        campusId: "nuist",
        name: "食堂档口",
        area: "东苑一食堂 1F",
        coordinate: CampusCoordinate(latitude: 32.2065, longitude: 118.7199)
    )

    let outdoorStore = CampusStoreOption(
        id: storeID,
        campusId: "nuist",
        name: "独立店铺",
        area: "东苑",
        coordinate: CampusCoordinate(latitude: 32.2067, longitude: 118.7210)
    )

    var canteens: [CampusCanteenOption] = [
        CampusCanteenOption(
            id: UUID(uuidString: "043F4FD4-9C3E-46A3-8959-E9341816CE6E")!,
            campusId: "nuist",
            name: "东苑一食堂",
            coordinate: includeCanteenCoordinate
                ? CampusCoordinate(latitude: 32.2064, longitude: 118.7198)
                : nil,
            floors: [
                CampusCanteenFloorOption(
                    id: UUID(uuidString: "9139DD28-1C2F-4E2A-A697-4C4CC2A3F36A")!,
                    floorOrder: 1,
                    floorLabel: "1F",
                    stores: [canteenStore]
                )
            ]
        )
    ]

    if includeSecondCanteenWithoutCoordinate {
        canteens.append(
            CampusCanteenOption(
                id: UUID(uuidString: "6BD2A8DA-080F-4C31-A194-D7A317C26ADE")!,
                campusId: "nuist",
                name: "缺坐标食堂",
                coordinate: nil,
                floors: [
                    CampusCanteenFloorOption(
                        id: UUID(uuidString: "9A17FD08-E399-42FD-98AF-6109BD8B170E")!,
                        floorOrder: 1,
                        floorLabel: "1F",
                        stores: []
                    )
                ]
            )
        )
    }

    return CampusStoreHierarchyOption(
        canteens: canteens,
        outdoorStores: includeOutdoorStore ? [outdoorStore] : []
    )
}

private func loadedDishCount(from state: StoreDishesLoadState) -> Int? {
    guard case .loaded(let dishes) = state else {
        return nil
    }
    return dishes.count
}

private func isFailed(_ state: StoreDishesLoadState) -> Bool {
    if case .failed = state {
        return true
    }
    return false
}

private enum StubError: Error {
    case dishRequestFailure
}

private actor StubCampusMenuRepository: CampusMenuRepository {
    private let hierarchy: CampusStoreHierarchyOption
    private let dishesByStoreID: [UUID: [CampusDishOption]]
    private var failuresRemainingByStore: [UUID: Int]
    private var dishFetchCountByStore: [UUID: Int] = [:]

    init(
        hierarchy: CampusStoreHierarchyOption,
        dishesByStoreID: [UUID: [CampusDishOption]],
        failuresRemainingByStore: [UUID: Int]
    ) {
        self.hierarchy = hierarchy
        self.dishesByStoreID = dishesByStoreID
        self.failuresRemainingByStore = failuresRemainingByStore
    }

    func fetchStoreHierarchy(campusId: String) async throws -> CampusStoreHierarchyOption {
        hierarchy
    }

    func fetchStores(campusId: String) async throws -> [CampusStoreOption] {
        hierarchy.flattenedStores
    }

    func fetchDishes(storeId: UUID) async throws -> [CampusDishOption] {
        dishFetchCountByStore[storeId, default: 0] += 1

        if let failuresRemaining = failuresRemainingByStore[storeId], failuresRemaining > 0 {
            failuresRemainingByStore[storeId] = failuresRemaining - 1
            throw StubError.dishRequestFailure
        }

        return dishesByStoreID[storeId] ?? []
    }

    func dishFetchCount(for storeId: UUID) -> Int {
        dishFetchCountByStore[storeId, default: 0]
    }
}
