import Testing
@testable import CoreStorage

@Test
func moduleNameNotEmpty() {
    #expect(!CoreStorageModule.name.isEmpty)
}
