#if os(iOS)
import SwiftUI
import CoreDomain

public struct RecommendationHomeView: View {
    @ObservedObject private var viewModel: RecommendationViewModel
    private let userNamePlaceholder = "<用户名>"

    public init(viewModel: RecommendationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    headerTextSection
                    heroRecommendationCard

                    if viewModel.isColdStart {
                        coldStartBanner
                    }

                    if let generatedAt = viewModel.recommendation?.generatedAt {
                        Text("基于 \(viewModel.logCount) 条饮食记录生成 · \(Self.timestampFormatter.string(from: generatedAt))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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

    private var headerTextSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(timeContext.greetingWord)好，\(userNamePlaceholder)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text("您的\(timeContext.mealLabel)推荐：")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var heroRecommendationCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.black)

            // Blank image placeholder for the first design pass.
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [8, 6]))
                )
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 34, weight: .semibold))
                        Text("图片占位")
                            .font(.footnote.weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.52))
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 80)

            LinearGradient(
                colors: [.clear, .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(primaryTitle)
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(primarySubtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(2)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 16, x: 0, y: 8)
    }

    private var primaryTitle: String {
        if viewModel.isLoading && highlightedMeal == nil {
            return "正在生成推荐..."
        }
        return highlightedMeal?.dishName ?? "暂无推荐"
    }

    private var primarySubtitle: String {
        guard let meal = highlightedMeal else {
            return "先记录几顿饭，推荐会更准确。"
        }

        var segments: [String] = [meal.storeName]
        if let estimatedPrice = meal.estimatedPrice {
            segments.append("约 ¥\(Int(estimatedPrice.rounded()))")
        }
        return segments.joined(separator: " · ")
    }

    private var highlightedMeal: RecommendedMeal? {
        viewModel.recommendedMeals.first(where: { $0.mealType == timeContext.mealType })
            ?? viewModel.recommendedMeals.first
    }

    private var timeContext: RecommendationTimeContext {
        RecommendationTimeContext.resolve(from: Date())
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

private struct RecommendationTimeContext {
    let greetingWord: String
    let mealLabel: String
    let mealType: MealType

    static func resolve(from date: Date, calendar: Calendar = .current) -> RecommendationTimeContext {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let minutes = (hour * 60) + minute

        let greetingWord: String
        switch minutes {
        case 5 * 60 ..< 11 * 60:
            greetingWord = "早上"
        case 11 * 60 ..< 14 * 60:
            greetingWord = "中午"
        case 14 * 60 ..< 18 * 60:
            greetingWord = "下午"
        default:
            greetingWord = "晚上"
        }

        let mealLabel: String
        let mealType: MealType
        switch minutes {
        case 4 * 60 ..< 10 * 60 + 30:
            mealLabel = "早饭"
            mealType = .breakfast
        case 10 * 60 + 30 ..< 15 * 60:
            mealLabel = "午饭"
            mealType = .lunch
        default:
            mealLabel = "晚饭"
            mealType = .dinner
        }

        return RecommendationTimeContext(
            greetingWord: greetingWord,
            mealLabel: mealLabel,
            mealType: mealType
        )
    }
}
#endif
