import Testing
@testable import FeatureReview

@Test
func moduleNameNotEmpty() {
    #expect(!FeatureReviewModule.name.isEmpty)
}
