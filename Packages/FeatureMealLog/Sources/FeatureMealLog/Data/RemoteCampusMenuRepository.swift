import Foundation
import CoreDomain
import CoreNetworking

public actor RemoteCampusMenuRepository: CampusMenuRepository {
    private let client: any NetworkClient

    public init(client: any NetworkClient) {
        self.client = client
    }

    public convenience init(baseURL: URL, session: URLSession = .shared) {
        self.init(client: URLSessionNetworkClient(baseURL: baseURL, session: session))
    }

    public func fetchStoreHierarchy(campusId: String) async throws -> CampusStoreHierarchyOption {
        let path = CampusMenuAPIContract.storesPathTemplate
            .replacingOccurrences(of: "{campusId}", with: campusId)
        let request = NetworkRequest(path: path, method: .get)
        return try await decodeStoreHierarchy(request, campusId: campusId)
    }

    public func fetchStores(campusId: String) async throws -> [CampusStoreOption] {
        let hierarchy = try await fetchStoreHierarchy(campusId: campusId)
        return hierarchy.flattenedStores
    }

    public func fetchDishes(storeId: UUID) async throws -> [CampusDishOption] {
        let path = CampusMenuAPIContract.dishesPathTemplate
            .replacingOccurrences(of: "{storeId}", with: storeId.uuidString)
        let request = NetworkRequest(path: path, method: .get)
        let dishes = try await decodeDishes(request)
        return dishes.map { $0.toDomain() }
    }

    private func decodeStoreHierarchy(_ request: NetworkRequest, campusId: String) async throws -> CampusStoreHierarchyOption {
        let data = try await client.data(for: request)
        let decoder = Self.makeDecoder()

        if let hierarchy = try? decoder.decode(CampusStoreHierarchyEnvelopeDTO.self, from: data) {
            return hierarchy.toDomain(campusId: campusId)
        }

        if let bareArray = try? decoder.decode([CampusStoreDTO].self, from: data) {
            return CampusStoreHierarchyOption(
                canteens: [],
                outdoorStores: bareArray.map { $0.toDomain(campusId: campusId) }
            )
        }

        let wrapped = try decoder.decode(StoreEnvelope.self, from: data)
        return CampusStoreHierarchyOption(
            canteens: [],
            outdoorStores: wrapped.stores.map { $0.toDomain(campusId: campusId) }
        )
    }

    private func decodeDishes(_ request: NetworkRequest) async throws -> [CampusDishDTO] {
        let data = try await client.data(for: request)
        let decoder = Self.makeDecoder()

        if let bareArray = try? decoder.decode([CampusDishDTO].self, from: data) {
            return bareArray
        }

        let wrapped = try decoder.decode(DishEnvelope.self, from: data)
        return wrapped.dishes
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

private struct StoreEnvelope: Decodable {
    let stores: [CampusStoreDTO]
}

private struct DishEnvelope: Decodable {
    let dishes: [CampusDishDTO]
}
