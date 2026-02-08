import Testing
@testable import FeatureCampusStore

@Test
func moduleNameNotEmpty() {
    #expect(!FeatureCampusStoreModule.name.isEmpty)
}
