#if os(iOS)
import Combine
import Foundation
import CoreDomain

public enum StoreDishesLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded([CampusDishOption])
    case empty
    case failed(String)
}

@MainActor
public final class CampusStoreMapViewModel: ObservableObject {
    @Published public private(set) var markers: [CampusStoreMarker]
    @Published public private(set) var hierarchy: CampusStoreHierarchyOption?
    @Published public private(set) var dishStateByStoreID: [UUID: StoreDishesLoadState]

    @Published public private(set) var campusBoundary: CampusBoundary
    @Published public private(set) var campusCenter: GeoPoint
    @Published public private(set) var userLocation: GeoPoint?
    @Published public private(set) var isUserInsideCampus = false

    @Published public var selectedMarker: CampusStoreMarker?
    @Published public private(set) var locationHint = "定位中..."
    @Published public private(set) var isLoadingStores = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var mapEmptyMessage: String?
    @Published public private(set) var hiddenCanteenCount = 0

    private let menuRepository: (any CampusMenuRepository)?
    private let staticHierarchy: CampusStoreHierarchyOption?
    private let campusId: String
    private var hasLoadedStores = false

    public init(
        markers: [CampusStoreMarker] = CampusStoreSeedData.nuistMarkers,
        hierarchy: CampusStoreHierarchyOption = CampusStoreSeedData.nuistHierarchy,
        campusBoundary: CampusBoundary = NUISTCampusRegion.boundary,
        campusCenter: GeoPoint = NUISTCampusRegion.center
    ) {
        self.markers = markers
        self.hierarchy = hierarchy
        self.dishStateByStoreID = [:]
        self.campusBoundary = campusBoundary
        self.campusCenter = campusCenter
        self.menuRepository = nil
        self.staticHierarchy = hierarchy
        self.campusId = "nuist"
        self.hiddenCanteenCount = hierarchy.canteens.filter { $0.coordinate == nil }.count
        self.mapEmptyMessage = markers.isEmpty ? "暂无可展示店铺/食堂点位。" : nil
    }

    public init(
        menuRepository: any CampusMenuRepository,
        campusId: String = "nuist",
        campusBoundary: CampusBoundary = NUISTCampusRegion.boundary,
        campusCenter: GeoPoint = NUISTCampusRegion.center
    ) {
        self.markers = []
        self.hierarchy = nil
        self.dishStateByStoreID = [:]
        self.campusBoundary = campusBoundary
        self.campusCenter = campusCenter
        self.menuRepository = menuRepository
        self.staticHierarchy = nil
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

        if menuRepository == nil, let staticHierarchy {
            hierarchy = staticHierarchy
            hasLoadedStores = true
            errorMessage = nil
            hiddenCanteenCount = staticHierarchy.canteens.filter { $0.coordinate == nil }.count
            mapEmptyMessage = markers.isEmpty ? "暂无可展示店铺/食堂点位。" : nil
            return
        }

        guard let menuRepository else {
            hasLoadedStores = true
            mapEmptyMessage = markers.isEmpty ? "暂无可展示店铺/食堂点位。" : nil
            return
        }

        isLoadingStores = true
        defer { isLoadingStores = false }

        do {
            let fetchedHierarchy = try await menuRepository.fetchStoreHierarchy(campusId: campusId)
            hierarchy = fetchedHierarchy

            let built = Self.buildMarkers(from: fetchedHierarchy)
            markers = built.markers
            hiddenCanteenCount = built.hiddenCanteenCount
            mapEmptyMessage = built.markers.isEmpty ? "暂无可展示店铺/食堂点位。" : nil
            errorMessage = nil
            hasLoadedStores = true

            if let selectedMarker {
                self.selectedMarker = built.markers.first(where: { $0.id == selectedMarker.id })
            }
        } catch {
            errorMessage = error.localizedDescription
            mapEmptyMessage = markers.isEmpty ? "暂无可展示店铺/食堂点位。" : nil
        }
    }

    public func loadDishesIfNeeded(storeId: UUID) async {
        let current = dishStateByStoreID[storeId] ?? .idle
        switch current {
        case .loading, .loaded, .empty:
            return
        case .idle, .failed:
            break
        }

        guard let menuRepository else {
            dishStateByStoreID[storeId] = .failed("暂无可用的数据源。")
            return
        }

        dishStateByStoreID[storeId] = .loading

        do {
            let dishes = try await menuRepository.fetchDishes(storeId: storeId)
            dishStateByStoreID[storeId] = dishes.isEmpty ? .empty : .loaded(dishes)
        } catch {
            dishStateByStoreID[storeId] = .failed(error.localizedDescription)
        }
    }

    public func retryDishes(for storeId: UUID) async {
        dishStateByStoreID[storeId] = .idle
        await loadDishesIfNeeded(storeId: storeId)
    }

    public func dishState(for storeId: UUID) -> StoreDishesLoadState {
        dishStateByStoreID[storeId] ?? .idle
    }

    public func canteen(for canteenId: UUID) -> CampusCanteenOption? {
        hierarchy?.canteens.first(where: { $0.id == canteenId })
    }

    public func floor(canteenId: UUID, floorId: UUID) -> CampusCanteenFloorOption? {
        canteen(for: canteenId)?.floors.first(where: { $0.id == floorId })
    }

    public func outdoorStore(storeId: UUID) -> CampusStoreOption? {
        hierarchy?.outdoorStores.first(where: { $0.id == storeId })
    }

    public func store(storeId: UUID) -> CampusStoreOption? {
        if let outdoorStore = outdoorStore(storeId: storeId) {
            return outdoorStore
        }

        return hierarchy?.canteens
            .flatMap(\.floors)
            .flatMap(\.stores)
            .first(where: { $0.id == storeId })
    }

    public func clearError() {
        errorMessage = nil
    }

    public func clearSelection() {
        selectedMarker = nil
    }
}

private extension CampusStoreMapViewModel {
    static func buildMarkers(from hierarchy: CampusStoreHierarchyOption) -> (markers: [CampusStoreMarker], hiddenCanteenCount: Int) {
        var hiddenCanteenCount = 0

        let canteenMarkers: [CampusStoreMarker] = hierarchy.canteens.compactMap { canteen in
            guard let coordinate = canteen.coordinate else {
                hiddenCanteenCount += 1
                return nil
            }

            let storeCount = canteen.floors.reduce(0) { partialResult, floor in
                partialResult + floor.stores.count
            }

            return CampusStoreMarker(
                id: "canteen-\(canteen.id.uuidString.lowercased())",
                kind: .canteen,
                title: canteen.name,
                subtitle: "\(canteen.floors.count) 层 · \(storeCount) 家店铺",
                coordinate: GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude),
                canteenId: canteen.id,
                storeId: nil
            )
        }

        let outdoorMarkers: [CampusStoreMarker] = hierarchy.outdoorStores.map { store in
            CampusStoreMarker(
                id: "store-\(store.id.uuidString.lowercased())",
                kind: .outdoorStore,
                title: store.name,
                subtitle: store.area,
                coordinate: GeoPoint(
                    latitude: store.coordinate.latitude,
                    longitude: store.coordinate.longitude
                ),
                canteenId: nil,
                storeId: store.id
            )
        }

        return (
            markers: (canteenMarkers + outdoorMarkers).sorted {
                $0.title.localizedCompare($1.title) == .orderedAscending
            },
            hiddenCanteenCount: hiddenCanteenCount
        )
    }
}
#endif
