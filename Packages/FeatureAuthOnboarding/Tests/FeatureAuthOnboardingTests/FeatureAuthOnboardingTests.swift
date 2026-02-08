import Testing
@testable import FeatureAuthOnboarding

@Test
func moduleNameNotEmpty() {
    #expect(!FeatureAuthOnboardingModule.name.isEmpty)
}
