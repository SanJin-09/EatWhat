import Testing
@testable import CoreAnalytics

@Test
func moduleNameNotEmpty() {
    #expect(!CoreAnalyticsModule.name.isEmpty)
}
