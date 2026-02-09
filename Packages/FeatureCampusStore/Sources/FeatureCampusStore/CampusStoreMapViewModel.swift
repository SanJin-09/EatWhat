#if os(iOS)
import Combine
import Foundation
import CoreDomain

@MainActor
public final class CampusStoreMapViewModel: ObservableObject {
    @Published public private(set) var stores: [CampusStore]
    @Published public private(set) var campusBoundary: CampusBoundary
    @Published public private(set) var campusCenter: GeoPoint
    @Published public private(set) var userLocation: GeoPoint?
    @Published public private(set) var isUserInsideCampus = false
    @Published public var selectedStore: CampusStore?
    @Published public private(set) var locationHint = "定位中..."
    @Published public private(set) var isLoadingStores = false
    @Published public private(set) var errorMessage: String?

    private let menuRepository: (any CampusMenuRepository)?
    private let campusId: String
    private var hasLoadedStores = false

    public init(
        stores: [CampusStore] = CampusStoreSeedData.nuistStores,
        campusBoundary: CampusBoundary = NUISTCampusRegion.boundary,
        campusCenter: GeoPoint = NUISTCampusRegion.center
    ) {
        self.stores = stores
        self.campusBoundary = campusBoundary
        self.campusCenter = campusCenter
        self.menuRepository = nil
        self.campusId = "nuist"
    }

    public init(
        menuRepository: any CampusMenuRepository,
        campusId: String = "nuist",
        campusBoundary: CampusBoundary = NUISTCampusRegion.boundary,
        campusCenter: GeoPoint = NUISTCampusRegion.center
    ) {
        self.stores = []
        self.campusBoundary = campusBoundary
        self.campusCenter = campusCenter
        self.menuRepository = menuRepository
        self.campusId = campusId
    }

    public func updateUserLocation(_ point: GeoPoint?) {
        userLocation = point
        guard let point else {
            isUserInsideCampus = false
            locationHint = "无法获取定位，请检查系统定位权限。"
            return
        }

        isUserInsideCampus = campusBoundary.contains(point)
        locationHint = isUserInsideCampus
            ? "你当前位于南京信息工程大学校区范围内。"
            : "你当前不在南信大校区，地图已限制在校内。"
    }

    public func loadStoresIfNeeded() async {
        guard !hasLoadedStores else { return }

        guard let menuRepository else {
            hasLoadedStores = true
            return
        }

        isLoadingStores = true
        defer { isLoadingStores = false }

        do {
            let remoteStores = try await menuRepository.fetchStores(campusId: campusId)
            stores = remoteStores.map {
                CampusStore(
                    id: $0.id,
                    name: $0.name,
                    area: $0.area,
                    dishHint: "加载中...",
                    coordinate: GeoPoint(
                        latitude: $0.coordinate.latitude,
                        longitude: $0.coordinate.longitude
                    )
                )
            }

            await loadDishHints(using: menuRepository)
            errorMessage = nil
            hasLoadedStores = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func clearError() {
        errorMessage = nil
    }

    public func clearSelection() {
        selectedStore = nil
    }

    private func loadDishHints(using menuRepository: any CampusMenuRepository) async {
        guard !stores.isEmpty else { return }

        let currentStores = stores
        var hints: [UUID: String] = [:]

        await withTaskGroup(of: (UUID, String?).self) { group in
            for store in currentStores {
                group.addTask {
                    do {
                        let dishes = try await menuRepository.fetchDishes(storeId: store.id)
                        return (store.id, dishes.first?.name)
                    } catch {
                        return (store.id, nil)
                    }
                }
            }

            for await (storeId, dishName) in group {
                hints[storeId] = dishName ?? "暂无推荐菜"
            }
        }

        stores = currentStores.map { store in
            CampusStore(
                id: store.id,
                name: store.name,
                area: store.area,
                dishHint: hints[store.id] ?? "暂无推荐菜",
                coordinate: store.coordinate
            )
        }

        if let selectedStore {
            self.selectedStore = stores.first(where: { $0.id == selectedStore.id })
        }
    }
}
#endif
