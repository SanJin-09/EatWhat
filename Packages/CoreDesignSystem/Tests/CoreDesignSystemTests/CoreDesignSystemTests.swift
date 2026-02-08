import Testing
@testable import CoreDesignSystem

@Test
func moduleNameNotEmpty() {
    #expect(!CoreDesignSystemModule.name.isEmpty)
}
