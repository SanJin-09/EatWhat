# EatWhat Packages

This directory contains local Swift packages for the EatWhat iOS app.

## Modules
- CoreFoundationKit
- CoreNetworking
- CoreStorage
- CoreDomain
- CoreDesignSystem
- CoreAnalytics
- FeatureAuthOnboarding
- FeatureMealLog
- FeatureNutrition
- FeatureRecommendation
- FeatureCampusStore
- FeatureReview
- FeatureProfileSettings

## Add into Xcode target
Packages are already linked in `/Users/sanjin/XcodeProject/EatWhat/EatWhat/EatWhat.xcodeproj`:
- All local package references were added.
- All package products are linked to the `EatWhat` app target.

Open `/Users/sanjin/XcodeProject/EatWhat/EatWhat.xcworkspace` directly and build the `EatWhat` scheme.

## Verify
Run:
- `xcodebuild -workspace EatWhat.xcworkspace -scheme EatWhat -configuration Debug -destination 'generic/platform=iOS' build`
