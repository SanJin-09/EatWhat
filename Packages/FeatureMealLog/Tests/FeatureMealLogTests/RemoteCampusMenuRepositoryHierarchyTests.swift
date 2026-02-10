import Foundation
import Testing
import CoreDomain
import CoreNetworking
@testable import FeatureMealLog

@Test
func fetchStoreHierarchyDecodesNewEnvelopePayload() async throws {
    let canteenID = UUID(uuidString: "9D656015-E077-4A55-9F22-702605788B62")!
    let floorID = UUID(uuidString: "E3D98697-37ED-48D1-A6F4-847B4FBC3E92")!
    let canteenStoreID = UUID(uuidString: "E4A2D9C8-201D-4FB4-A477-87D51AFFA377")!
    let outdoorStoreID = UUID(uuidString: "8F0456EF-2E2E-4539-8575-2CEAB3F6DFF3")!

    let payload = """
    {
      "canteens": [
        {
          "id": "\(canteenID.uuidString)",
          "name": "东苑一食堂",
          "latitude": 32.206443,
          "longitude": 118.719779,
          "floors": [
            {
              "id": "\(floorID.uuidString)",
              "floorOrder": 1,
              "floorLabel": "1F",
              "stores": [
                {
                  "id": "\(canteenStoreID.uuidString)",
                  "name": "一楼米线",
                  "area": "东苑一食堂 1F",
                  "locationType": "CANTEEN",
                  "canteenId": "\(canteenID.uuidString)",
                  "canteenName": "东苑一食堂",
                  "floorId": "\(floorID.uuidString)",
                  "floorOrder": 1,
                  "floorLabel": "1F",
                  "latitude": 32.2065,
                  "longitude": 118.7199
                }
              ]
            }
          ]
        }
      ],
      "outdoorStores": [
        {
          "id": "\(outdoorStoreID.uuidString)",
          "name": "北门早餐铺",
          "area": "北门",
          "locationType": "OUTDOOR",
          "canteenId": null,
          "canteenName": null,
          "floorId": null,
          "floorOrder": null,
          "floorLabel": null,
          "latitude": 32.2132,
          "longitude": 118.7177
        }
      ]
    }
    """

    let repository = RemoteCampusMenuRepository(
        client: StubNetworkClient(payloadsByPath: [
            "/campuses/nuist/stores": Data(payload.utf8)
        ])
    )

    let hierarchy = try await repository.fetchStoreHierarchy(campusId: "nuist")
    #expect(hierarchy.canteens.count == 1)
    #expect(hierarchy.outdoorStores.count == 1)
    #expect(hierarchy.canteens.first?.coordinate?.latitude == 32.206443)
    #expect(hierarchy.canteens.first?.coordinate?.longitude == 118.719779)

    let flattened = try await repository.fetchStores(campusId: "nuist")
    #expect(flattened.count == 2)
}

@Test
func fetchStoreHierarchyFallsBackToLegacyFlatArrayPayload() async throws {
    let storeID = UUID(uuidString: "D20F6EFD-C74D-42CB-9AAB-86800509BC70")!

    let payload = """
    [
      {
        "id": "\(storeID.uuidString)",
        "name": "独立店铺",
        "area": "东苑",
        "locationType": "OUTDOOR",
        "canteenId": null,
        "canteenName": null,
        "floorId": null,
        "floorOrder": null,
        "floorLabel": null,
        "latitude": 32.206746,
        "longitude": 118.721014
      }
    ]
    """

    let repository = RemoteCampusMenuRepository(
        client: StubNetworkClient(payloadsByPath: [
            "/campuses/nuist/stores": Data(payload.utf8)
        ])
    )

    let hierarchy = try await repository.fetchStoreHierarchy(campusId: "nuist")
    #expect(hierarchy.canteens.isEmpty)
    #expect(hierarchy.outdoorStores.count == 1)
    #expect(hierarchy.outdoorStores.first?.id == storeID)

    let flattened = try await repository.fetchStores(campusId: "nuist")
    #expect(flattened.count == 1)
    #expect(flattened.first?.id == storeID)
}

private struct StubNetworkClient: NetworkClient {
    let payloadsByPath: [String: Data]

    func data(for request: NetworkRequest) async throws -> Data {
        guard let payload = payloadsByPath[request.path] else {
            throw StubNetworkError.missingPayload(path: request.path)
        }

        return payload
    }
}

private enum StubNetworkError: Error {
    case missingPayload(path: String)
}
