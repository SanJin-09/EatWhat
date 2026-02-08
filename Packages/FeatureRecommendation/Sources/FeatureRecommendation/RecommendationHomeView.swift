#if os(iOS)
import SwiftUI
import CoreDomain

public struct RecommendationHomeView: View {
    @ObservedObject private var viewModel: RecommendationViewModel

    public init(viewModel: RecommendationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.recommendedMeals.isEmpty {
                    ProgressView("正在计算今日推荐...")
                } else if viewModel.recommendedMeals.isEmpty {
                    ContentUnavailableView(
                        "暂无推荐",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: Text("先记录几顿饭，推荐会更准确。")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if viewModel.isColdStart {
                                coldStartBanner
                            }

                            if let generatedAt = viewModel.recommendation?.generatedAt {
                                Text("基于 \(viewModel.logCount) 条饮食记录生成 · \(Self.timestampFormatter.string(from: generatedAt))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(viewModel.recommendedMeals) { meal in
                                RecommendationCardView(meal: meal)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("今日推荐")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.load()
                        }
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .alert(
            "加载失败",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { visible in
                    if !visible {
                        viewModel.clearError()
                    }
                }
            )
        ) {
            Button("知道了", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var coldStartBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("继续记录可提升推荐准确率")
                .font(.headline)
            Text("当你累计更多早餐/午餐/晚餐记录后，推荐会优先命中你常去店铺和高频菜品。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()
}

private struct RecommendationCardView: View {
    let meal: RecommendedMeal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(meal.mealType.displayName, systemImage: meal.mealType.recommendationSymbol)
                    .font(.headline)
                Spacer()
                if let price = meal.estimatedPrice {
                    Text("¥\(price, specifier: "%.0f")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(meal.dishName)
                .font(.title3.weight(.semibold))

            Text(meal.storeName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(meal.reason)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension MealType {
    var recommendationSymbol: String {
        switch self {
        case .breakfast:
            return "sunrise"
        case .lunch:
            return "sun.max"
        case .dinner:
            return "moon.stars"
        case .snack:
            return "cup.and.saucer"
        }
    }
}
#endif
