#if os(iOS)
import Combine
import Foundation

@MainActor
public final class CampusStoreMapViewModel: ObservableObject {
    @Published public private(set) var stores: [CampusStore]
    @Published public private(set) var campusBoundary: CampusBoundary
    @Published public private(set) var campusCenter: GeoPoint
    @Published public private(set) var userLocation: GeoPoint?
    @Published public private(set) var isUserInsideCampus = false
    @Published public var selectedStore: CampusStore?
    @Published public private(set) var locationHint = "定位中..."

    public init(
        stores: [CampusStore] = CampusStoreSeedData.nuistStores,
        campusBoundary: CampusBoundary = NUISTCampusRegion.boundary,
        campusCenter: GeoPoint = NUISTCampusRegion.center
    ) {
        self.stores = stores
        self.campusBoundary = campusBoundary
        self.campusCenter = campusCenter
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

    public func clearSelection() {
        selectedStore = nil
    }
}
#endif
