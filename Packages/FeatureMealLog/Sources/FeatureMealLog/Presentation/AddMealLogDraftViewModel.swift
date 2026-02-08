import Foundation
import CoreLocation
import CoreDomain

@MainActor
final class AddMealLogDraftViewModel: ObservableObject {
    enum DishSelection: Hashable {
        case preset(UUID)
        case custom
    }

    @Published private(set) var stores: [CampusStoreOption] = []
    @Published private(set) var selectedStore: CampusStoreOption?
    @Published private(set) var dishes: [CampusDishOption] = []
    @Published private(set) var selectedNutrition: NutrientSnapshot?
    @Published private(set) var mapCenter: CampusCoordinate
    @Published private(set) var locationHint = "定位中..."
    @Published private(set) var isLoadingStores = false
    @Published private(set) var isLoadingDishes = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastAutoSelectedStoreName: String?

    @Published var storeSearchText = ""
    @Published var dishSelection: DishSelection = .custom
    @Published var customDishName = ""
    @Published var priceText = "" {
        didSet {
            if isProgrammaticPriceUpdate { return }
            hasManualPriceEdit = true
        }
    }

    private let menuRepository: any CampusMenuRepository
    private let campusId: String
    private let campusBounds: CampusBounds
    private var nearestStoreTask: Task<Void, Never>?
    private var loadDishesTask: Task<Void, Never>?
    private var hasAppliedInitialUserLocation = false
    private var hasManualPriceEdit = false
    private var isProgrammaticPriceUpdate = false

    init(
        menuRepository: any CampusMenuRepository,
        campusId: String = "nuist",
        fallbackCenter: CampusCoordinate = CampusCoordinate(latitude: 32.2066, longitude: 118.7184),
        campusBounds: CampusBounds = .nuist
    ) {
        self.menuRepository = menuRepository
        self.campusId = campusId
        self.mapCenter = fallbackCenter
        self.campusBounds = campusBounds
    }

    var storePickerOptions: [CampusStoreOption] {
        let keyword = storeSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = stores.sorted { lhs, rhs in
            distanceMeters(from: mapCenter, to: lhs.coordinate) < distanceMeters(from: mapCenter, to: rhs.coordinate)
        }

        guard !keyword.isEmpty else {
            return sorted
        }

        let matched = sorted.filter {
            $0.name.localizedCaseInsensitiveContains(keyword) ||
                $0.area.localizedCaseInsensitiveContains(keyword)
        }

        guard !matched.isEmpty else {
            return sorted
        }

        guard let selectedStore, !matched.contains(where: { $0.id == selectedStore.id }) else {
            return matched
        }

        return [selectedStore] + matched
    }

    var isUsingCustomDish: Bool {
        if case .custom = dishSelection {
            return true
        }
        return false
    }

    func load() async {
        guard stores.isEmpty else { return }

        isLoadingStores = true
        defer { isLoadingStores = false }

        do {
            let fetchedStores = try await menuRepository.fetchStores(campusId: campusId)
            stores = fetchedStores

            guard !fetchedStores.isEmpty else {
                errorMessage = "当前校区暂无店铺数据。"
                return
            }

            selectNearestStoreForCurrentCenter()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateMapCenter(_ newCenter: CampusCoordinate) {
        let clampedCenter = campusBounds.clamped(newCenter)
        mapCenter = clampedCenter
        scheduleNearestStoreSelection()
    }

    func updateUserLocation(_ location: CampusCoordinate?) {
        guard let location else {
            locationHint = "无法获取定位，请拖动地图选择附近店铺。"
            return
        }

        locationHint = campusBounds.contains(location)
            ? "已定位到校内，可拖动地图微调店铺定位。"
            : "当前定位在校外，已将地图限制在南信大范围。"

        guard !hasAppliedInitialUserLocation else { return }
        hasAppliedInitialUserLocation = true
        updateMapCenter(location)
    }

    func selectStoreManually(id: UUID) {
        guard let store = stores.first(where: { $0.id == id }) else { return }
        lastAutoSelectedStoreName = nil
        selectStore(store, recenterMap: true)
    }

    func setDishSelection(_ selection: DishSelection) {
        dishSelection = selection
        syncDishDependentFields(forcePriceUpdate: true)
    }

    func clearError() {
        errorMessage = nil
    }

    func makeInput(date: Date, mealType: MealType) throws -> NewMealLogInput {
        guard let selectedStore else {
            throw MealLogDomainError.invalidInput
        }

        let dishName: String
        let dishId: UUID?
        let nutrition: NutrientSnapshot?

        switch dishSelection {
        case .preset(let dishID):
            guard let selectedDish = dishes.first(where: { $0.id == dishID }) else {
                throw MealLogDomainError.invalidInput
            }
            dishName = selectedDish.name
            dishId = selectedDish.id
            nutrition = selectedDish.nutrition
        case .custom:
            let trimmedCustomDish = customDishName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedCustomDish.isEmpty else {
                throw MealLogDomainError.invalidInput
            }
            dishName = trimmedCustomDish
            dishId = nil
            nutrition = nil
        }

        let parsedPrice: Double?
        let trimmedPrice = priceText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPrice.isEmpty {
            parsedPrice = nil
        } else if let value = Double(trimmedPrice), value >= 0 {
            parsedPrice = value
        } else {
            throw MealLogDomainError.invalidInput
        }

        return NewMealLogInput(
            date: date,
            mealType: mealType,
            storeId: selectedStore.id,
            dishId: dishId,
            storeName: selectedStore.name,
            dishName: dishName,
            price: parsedPrice,
            nutrition: nutrition
        )
    }

    private func scheduleNearestStoreSelection() {
        nearestStoreTask?.cancel()
        nearestStoreTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self?.selectNearestStoreForCurrentCenter()
        }
    }

    private func selectNearestStoreForCurrentCenter() {
        guard let nearest = stores.min(by: {
            distanceMeters(from: mapCenter, to: $0.coordinate) < distanceMeters(from: mapCenter, to: $1.coordinate)
        }) else {
            return
        }

        lastAutoSelectedStoreName = nearest.name
        selectStore(nearest, recenterMap: false)
    }

    private func selectStore(_ store: CampusStoreOption, recenterMap: Bool) {
        if recenterMap {
            mapCenter = store.coordinate
        }

        guard selectedStore?.id != store.id else { return }

        selectedStore = store
        loadDishes(storeID: store.id)
    }

    private func loadDishes(storeID: UUID) {
        loadDishesTask?.cancel()
        loadDishesTask = Task { [weak self] in
            guard let self else { return }
            self.isLoadingDishes = true
            defer { self.isLoadingDishes = false }

            do {
                let fetched = try await self.menuRepository.fetchDishes(storeId: storeID)
                guard !Task.isCancelled else { return }
                self.dishes = fetched

                if let firstDish = fetched.first {
                    self.dishSelection = .preset(firstDish.id)
                } else {
                    self.dishSelection = .custom
                    self.customDishName = ""
                }

                self.syncDishDependentFields(forcePriceUpdate: true)
                self.errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                self.dishes = []
                self.dishSelection = .custom
                self.customDishName = ""
                self.setPriceProgrammatically("")
                self.selectedNutrition = nil
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func syncDishDependentFields(forcePriceUpdate: Bool) {
        switch dishSelection {
        case .preset(let dishID):
            guard let selectedDish = dishes.first(where: { $0.id == dishID }) else {
                selectedNutrition = nil
                setPriceProgrammatically("")
                return
            }

            selectedNutrition = selectedDish.nutrition
            if forcePriceUpdate || !hasManualPriceEdit {
                setPriceProgrammatically(Self.priceText(from: selectedDish.price))
                hasManualPriceEdit = false
            }

        case .custom:
            selectedNutrition = nil
            if forcePriceUpdate {
                setPriceProgrammatically("")
                hasManualPriceEdit = false
            }
        }
    }

    private func setPriceProgrammatically(_ text: String) {
        isProgrammaticPriceUpdate = true
        priceText = text
        isProgrammaticPriceUpdate = false
    }

    private static func priceText(from price: Double?) -> String {
        guard let price else { return "" }
        return String(format: "%.2f", price).replacingOccurrences(of: ".00", with: "")
    }

    private func distanceMeters(from lhs: CampusCoordinate, to rhs: CampusCoordinate) -> CLLocationDistance {
        let lhsLocation = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
        let rhsLocation = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)
        return lhsLocation.distance(from: rhsLocation)
    }
}

struct CampusBounds {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    static let nuist = CampusBounds(
        minLatitude: 32.1932,
        maxLatitude: 32.2198,
        minLongitude: 118.7032,
        maxLongitude: 118.7338
    )

    func contains(_ point: CampusCoordinate) -> Bool {
        point.latitude >= minLatitude &&
            point.latitude <= maxLatitude &&
            point.longitude >= minLongitude &&
            point.longitude <= maxLongitude
    }

    func clamped(_ point: CampusCoordinate) -> CampusCoordinate {
        CampusCoordinate(
            latitude: min(max(point.latitude, minLatitude), maxLatitude),
            longitude: min(max(point.longitude, minLongitude), maxLongitude)
        )
    }
}
