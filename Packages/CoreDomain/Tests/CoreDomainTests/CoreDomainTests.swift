import Testing
@testable import CoreDomain

@Test
func moduleNameNotEmpty() {
    #expect(!CoreDomainModule.name.isEmpty)
}
