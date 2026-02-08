import Testing
@testable import CoreFoundationKit

@Test
func moduleNameNotEmpty() {
    #expect(!CoreFoundationKitModule.name.isEmpty)
}
