#if os(iOS)
import SwiftUI
import CoreDomain
import UIKit

public struct RecommendationHomeView: View {
    @ObservedObject private var viewModel: RecommendationViewModel
    private let userNamePlaceholder = "<用户名>"
    @State private var heroImageName = RecommendationHomeView.randomHeroImageName()
    @State private var isColdStartBannerVisible = true

    public init(viewModel: RecommendationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    headerTextSection
                    heroRecommendationCard
                    heroStackCarouselSection
                    
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
        .onAppear {
            heroImageName = Self.randomHeroImageName()
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
            
            Spacer()
            
            if viewModel.isColdStart && isColdStartBannerVisible {
                coldStartBanner
            }
        }
    }

    private var heroRecommendationCard: some View {
        
        VStack(alignment: .leading){
            Text("您的\(timeContext.mealLabel)推荐：")
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            ZStack(alignment: .bottom) {
                heroImageLayer
                
                heroTextLayer
            }
            .background(Color.black)
            .cornerRadius(32) // 更大的圆角
            .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 15)
        }
    }

    @ViewBuilder
    private var heroImageLayer: some View {
        GeometryReader{ geometry in
            if let image = UIImage(named: heroImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
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
                            Text("暂无图片")
                                .font(.footnote.weight(.medium))
                        }
                        .foregroundStyle(.white.opacity(0.52))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)
            }
            
            if let image = UIImage(named: heroImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .blur(radius: 20) // 高斯模糊半径，数值越大雾感越强
                    .mask(
                        // 遮罩：上部透明(看不见模糊)，下部黑色(显示模糊)
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.4), // 0-40% 保持清晰
                                .init(color: .black, location: 0.9)  // 底部完全模糊
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .black.opacity(0.1),
                    .black.opacity(0.6), // 底部加深，提高对比度
                    .black.opacity(0.9)
                ]),
                startPoint: .center, // 从中间开始渐变
                endPoint: .bottom
            )
        }
        .frame(height: 320)
    }
    
    private var heroTextLayer: some View {
        VStack(alignment: .leading) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 6) {
                Text(primaryTitle)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text(primarySubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 24)
            .padding(.horizontal, 24)
        }
        .frame(height: 320)
    }

    private var heroStackCarouselSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("校园餐食灵感")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Self.heroStackCards) { card in
                        heroStackCarouselCard(card)
                    }
                }
                .padding(.trailing, 4)
                .padding(.bottom, 20)
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .padding(.horizontal, -20)
            
            Spacer()
        }
    }

    private func heroStackCarouselCard(_ card: HeroStackCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.80, green: 0.80, blue: 0.82))

                Image(systemName: card.placeholderSymbol)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text("图片占位")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.84))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.2), in: Capsule())
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 130)

            Text(card.title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)

            HStack(spacing: 8) {
                Circle()
                    .fill(card.badgeColor)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Image(systemName: card.badgeSymbol)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }

                Text(card.metricText)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(width: 190)
        .background(Self.heroStackCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 5)
        .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
            let scale = max(0.88, 1 - abs(phase.value) * 0.12)
            return effect.scaleEffect(scale)
        }

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
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("记录越多，推荐越准！")
                    .font(.headline)
                Text("推荐会优先命中你常去店铺和高频菜品，请多多记录早餐/午餐/晚餐吧。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .padding(.trailing, 24)

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isColdStartBannerVisible = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(.white.opacity(0.9), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()

    private static func randomHeroImageName() -> String {
        heroImageNames.randomElement() ?? "HeroMalaTang"
    }

    private static let heroImageNames = [
        "HeroMalaTang",
        "HeroBraisedChickenRice",
    ]

    private static let heroStackCards: [HeroStackCard] = [
        HeroStackCard(
            title: "轻食能量碗",
            metricText: "420+",
            placeholderSymbol: "leaf.fill",
            badgeColor: Color.orange,
            badgeSymbol: "flame.fill"
        ),
        HeroStackCard(
            title: "番茄牛肉面",
            metricText: "650+",
            placeholderSymbol: "fork.knife",
            badgeColor: Color.orange,
            badgeSymbol: "clock.fill"
        ),
        HeroStackCard(
            title: "维C沙拉盒",
            metricText: "300+",
            placeholderSymbol: "carrot.fill",
            badgeColor: Color.green,
            badgeSymbol: "leaf.fill"
        ),
    ]

    private static let heroStackCardBackground = Color(red: 1.0, green: 199.0 / 255.0, blue: 44.0 / 255.0)
}

private struct HeroStackCard: Identifiable {
    let id = UUID()
    let title: String
    let metricText: String
    let placeholderSymbol: String
    let badgeColor: Color
    let badgeSymbol: String
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
#Preview {
    RecommendationHomeView(
        viewModel: RecommendationViewModel(
            getMealLogsUseCase: PreviewGetMealLogsUseCase()
        )
    )
}

#if DEBUG
private struct PreviewGetMealLogsUseCase: GetMealLogsUseCaseProtocol {
    func execute() async throws -> [MealLog] {
        let calendar = Calendar.current
        let now = Date()
        return [
            MealLog(
                id: UUID(),
                date: calendar.date(byAdding: .hour, value: -1, to: now) ?? now,
                mealType: .lunch,
                storeName: "东区食堂 · 轻食",
                dishName: "鸡胸藜麦碗",
                price: 22
            ),
            MealLog(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                mealType: .dinner,
                storeName: "西区食堂 · 烧腊",
                dishName: "叉烧双拼饭",
                price: 24
            ),
            MealLog(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                mealType: .breakfast,
                storeName: "北门早餐铺",
                dishName: "豆浆 + 鲜肉包",
                price: 8
            )
        ]
    }
}
#endif


