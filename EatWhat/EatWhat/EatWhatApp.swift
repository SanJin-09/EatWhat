import SwiftUI

@main
struct EatWhatApp: App {
    private let container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            AppRouterView(container: container)
        }
    }
}
