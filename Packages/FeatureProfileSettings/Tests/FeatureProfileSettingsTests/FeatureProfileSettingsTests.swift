import Testing
@testable import FeatureProfileSettings

@Test
func moduleNameNotEmpty() {
    #expect(!FeatureProfileSettingsModule.name.isEmpty)
}
