import SwiftUI
import FeatureCampusStore
import FeatureMealLog
import FeatureRecommendation

enum AppTab: Hashable {
    case home
    case logs
    case stores
    case nutrition
    case profile
}

@MainActor
struct AppRouterView: View {
    let container: DependencyContainer
    @StateObject private var campusStoreViewModel: CampusStoreMapViewModel
    @StateObject private var recommendationViewModel: RecommendationViewModel
    @StateObject private var mealLogViewModel: MealLogListViewModel
    @State private var selectedTab: AppTab = .home

    init(container: DependencyContainer) {
        self.container = container
        _campusStoreViewModel = StateObject(
            wrappedValue: container.makeCampusStoreMapViewModel()
        )
        _recommendationViewModel = StateObject(
            wrappedValue: container.makeRecommendationViewModel()
        )
        _mealLogViewModel = StateObject(
            wrappedValue: container.makeMealLogListViewModel()
        )
    }

    var body: some View {
        fullTabContainer
    }

    private var fullTabContainer: some View {
        TabView(selection: $selectedTab) {
            RecommendationHomeView(viewModel: recommendationViewModel)
                .tabItem {
                    Label(AppTab.home.title, systemImage: AppTab.home.systemImage)
                }
                .tag(AppTab.home)

            MealLogHomeView(
                viewModel: mealLogViewModel,
                campusMenuRepository: container.makeCampusMenuRepository()
            )
                .tabItem {
                    Label(AppTab.logs.title, systemImage: AppTab.logs.systemImage)
                }
                .tag(AppTab.logs)

            CampusStoreTabView(viewModel: campusStoreViewModel)
                .tabItem {
                    Label(AppTab.stores.title, systemImage: AppTab.stores.systemImage)
                }
                .tag(AppTab.stores)

            tabPlaceholder(title: "营养", tab: .nutrition)
                .tabItem {
                    Label(AppTab.nutrition.title, systemImage: AppTab.nutrition.systemImage)
                }
                .tag(AppTab.nutrition)

            tabPlaceholder(title: "我的", tab: .profile)
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage)
                }
                .tag(AppTab.profile)
        }
    }

    @ViewBuilder
    private func tabPlaceholder(title: String, tab: AppTab) -> some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 36))
                Text("\(title)模块初始化完成")
                    .font(.headline)
                Text("Container created at: \(container.createdAt.formatted())")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle(title)
        }
    }

}

private extension AppTab {
    var title: String {
        switch self {
        case .home:
            return "推荐"
        case .logs:
            return "记录"
        case .stores:
            return "店铺"
        case .nutrition:
            return "营养"
        case .profile:
            return "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "list.bullet.rectangle.portrait.fill"
        case .logs:
            return "square.and.pencil"
        case .stores:
            return "map"
        case .nutrition:
            return "chart.bar.xaxis"
        case .profile:
            return "person.crop.circle"
        }
    }
}

#Preview {
    AppRouterView(container: DependencyContainer())
}
