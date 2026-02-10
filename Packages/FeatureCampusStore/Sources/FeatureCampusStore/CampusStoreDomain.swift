import Foundation
import CoreDomain

public struct GeoPoint: Equatable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct CampusBoundary: Equatable, Sendable {
    public let minLatitude: Double
    public let maxLatitude: Double
    public let minLongitude: Double
    public let maxLongitude: Double

    public init(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) {
        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }

    public init(enclosing points: [GeoPoint]) {
        precondition(!points.isEmpty, "CampusBoundary requires at least one point.")

        let latitudes = points.map(\.latitude)
        let longitudes = points.map(\.longitude)

        self.init(
            minLatitude: latitudes.min() ?? 0,
            maxLatitude: latitudes.max() ?? 0,
            minLongitude: longitudes.min() ?? 0,
            maxLongitude: longitudes.max() ?? 0
        )
    }

    public func contains(_ point: GeoPoint) -> Bool {
        point.latitude >= minLatitude &&
            point.latitude <= maxLatitude &&
            point.longitude >= minLongitude &&
            point.longitude <= maxLongitude
    }

    public func clamped(_ point: GeoPoint) -> GeoPoint {
        GeoPoint(
            latitude: min(max(point.latitude, minLatitude), maxLatitude),
            longitude: min(max(point.longitude, minLongitude), maxLongitude)
        )
    }
}

public enum NUISTCampusRegion {
    // Approximate boundary path of NUIST (Xianlin campus), used for map overlay.
    public static let outline: [GeoPoint] = [
        GeoPoint(latitude: 32.2137, longitude: 118.7114),
        GeoPoint(latitude: 32.2142, longitude: 118.7155),
        GeoPoint(latitude: 32.2138, longitude: 118.7202),
        GeoPoint(latitude: 32.2128, longitude: 118.7243),
        GeoPoint(latitude: 32.2103, longitude: 118.7263),
        GeoPoint(latitude: 32.2067, longitude: 118.7269),
        GeoPoint(latitude: 32.2024, longitude: 118.7260),
        GeoPoint(latitude: 32.1996, longitude: 118.7245),
        GeoPoint(latitude: 32.1982, longitude: 118.7216),
        GeoPoint(latitude: 32.1980, longitude: 118.7172),
        GeoPoint(latitude: 32.1988, longitude: 118.7135),
        GeoPoint(latitude: 32.2007, longitude: 118.7108),
        GeoPoint(latitude: 32.2043, longitude: 118.7095),
        GeoPoint(latitude: 32.2082, longitude: 118.7097),
        GeoPoint(latitude: 32.2115, longitude: 118.7104)
    ]

    public static let boundary = CampusBoundary(enclosing: outline)

    public static let center = GeoPoint(latitude: 32.2066, longitude: 118.7184)
}

public enum CampusStoreMarkerKind: String, Equatable, Sendable {
    case canteen
    case outdoorStore
}

public struct CampusStoreMarker: Identifiable, Equatable, Sendable {
    public let id: String
    public let kind: CampusStoreMarkerKind
    public let title: String
    public let subtitle: String
    public let coordinate: GeoPoint
    public let canteenId: UUID?
    public let storeId: UUID?

    public init(
        id: String,
        kind: CampusStoreMarkerKind,
        title: String,
        subtitle: String,
        coordinate: GeoPoint,
        canteenId: UUID?,
        storeId: UUID?
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.canteenId = canteenId
        self.storeId = storeId
    }
}

public enum CampusStoreSeedData {
    public static let nuistHierarchy: CampusStoreHierarchyOption = {
        let campusId = "nuist"

        let storeOne = CampusStoreOption(
            id: UUID(uuidString: "3E4B4A79-B1AC-4F7D-A4E8-FCB99B6545D0")!,
            campusId: campusId,
            name: "一食堂米线档",
            area: "一食堂 1F",
            coordinate: CampusCoordinate(latitude: 32.2050, longitude: 118.7168)
        )

        let storeTwo = CampusStoreOption(
            id: UUID(uuidString: "850AD607-443D-4428-9D9B-D1367C6228A8")!,
            campusId: campusId,
            name: "北门早餐铺",
            area: "北门",
            coordinate: CampusCoordinate(latitude: 32.2132, longitude: 118.7177)
        )

        return CampusStoreHierarchyOption(
            canteens: [
                CampusCanteenOption(
                    id: UUID(uuidString: "4CE188EB-8E5E-4F63-AB6F-15E50D656D5C")!,
                    campusId: campusId,
                    name: "一食堂",
                    coordinate: CampusCoordinate(latitude: 32.2051, longitude: 118.7169),
                    floors: [
                        CampusCanteenFloorOption(
                            id: UUID(uuidString: "4C1885A7-26C2-493C-8492-FAEF760D658D")!,
                            floorOrder: 1,
                            floorLabel: "1F",
                            stores: [storeOne]
                        )
                    ]
                )
            ],
            outdoorStores: [storeTwo]
        )
    }()

    public static let nuistMarkers: [CampusStoreMarker] = {
        let canteenMarkers = nuistHierarchy.canteens.compactMap { canteen in
            marker(for: canteen)
        }

        let outdoorMarkers = nuistHierarchy.outdoorStores.map { store in
            marker(for: store)
        }

        return canteenMarkers + outdoorMarkers
    }()

    private static func marker(for canteen: CampusCanteenOption) -> CampusStoreMarker? {
        guard let coordinate = canteen.coordinate else {
            return nil
        }

        return CampusStoreMarker(
            id: "canteen-\(canteen.id.uuidString.lowercased())",
            kind: .canteen,
            title: canteen.name,
            subtitle: "\(canteen.floors.count) 层",
            coordinate: GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude),
            canteenId: canteen.id,
            storeId: nil
        )
    }

    private static func marker(for store: CampusStoreOption) -> CampusStoreMarker {
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
}
