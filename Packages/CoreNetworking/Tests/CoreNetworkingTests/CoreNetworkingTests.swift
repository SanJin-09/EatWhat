import Testing
@testable import CoreNetworking

@Test
func moduleNameNotEmpty() {
    #expect(!CoreNetworkingModule.name.isEmpty)
}
