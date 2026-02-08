import Testing
@testable import FeatureMealLog

@Test
func moduleNameNotEmpty() {
    #expect(!FeatureMealLogModule.name.isEmpty)
}
