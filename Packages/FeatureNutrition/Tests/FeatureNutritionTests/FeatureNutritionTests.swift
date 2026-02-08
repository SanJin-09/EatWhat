import Testing
@testable import FeatureNutrition

@Test
func moduleNameNotEmpty() {
    #expect(!FeatureNutritionModule.name.isEmpty)
}
