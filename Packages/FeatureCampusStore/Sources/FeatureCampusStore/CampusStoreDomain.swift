import Foundation

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
    // Rough rectangle that covers NUIST (Xianlin campus) core area.
    public static let boundary = CampusBoundary(
        minLatitude: 32.1932,
        maxLatitude: 32.2198,
        minLongitude: 118.7032,
        maxLongitude: 118.7338
    )

    public static let center = GeoPoint(latitude: 32.2066, longitude: 118.7184)
}

public struct CampusStore: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let area: String
    public let dishHint: String
    public let coordinate: GeoPoint

    public init(
        id: UUID = UUID(),
        name: String,
        area: String,
        dishHint: String,
        coordinate: GeoPoint
    ) {
        self.id = id
        self.name = name
        self.area = area
        self.dishHint = dishHint
        self.coordinate = coordinate
    }
}

public enum CampusStoreSeedData {
    // Initial pins for NUIST; can be replaced by backend-sourced data later.
    public static let nuistStores: [CampusStore] = [
        CampusStore(
            name: "一食堂米线档",
            area: "一食堂",
            dishHint: "番茄牛肉米线",
            coordinate: GeoPoint(latitude: 32.2050, longitude: 118.7168)
        ),
        CampusStore(
            name: "二食堂盖浇饭",
            area: "二食堂",
            dishHint: "黑椒鸡腿饭",
            coordinate: GeoPoint(latitude: 32.2077, longitude: 118.7204)
        ),
        CampusStore(
            name: "清真窗口",
            area: "三食堂",
            dishHint: "牛肉面",
            coordinate: GeoPoint(latitude: 32.2104, longitude: 118.7222)
        ),
        CampusStore(
            name: "北门早餐铺",
            area: "北门生活区",
            dishHint: "豆浆 + 灌饼",
            coordinate: GeoPoint(latitude: 32.2132, longitude: 118.7177)
        ),
        CampusStore(
            name: "东苑轻食店",
            area: "东苑",
            dishHint: "鸡胸肉沙拉碗",
            coordinate: GeoPoint(latitude: 32.2037, longitude: 118.7268)
        ),
        CampusStore(
            name: "西苑麻辣烫",
            area: "西苑",
            dishHint: "微辣麻辣烫",
            coordinate: GeoPoint(latitude: 32.2020, longitude: 118.7116)
        )
    ]
}
