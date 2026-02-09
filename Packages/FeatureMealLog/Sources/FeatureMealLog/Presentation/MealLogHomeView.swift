import SwiftUI
import CoreDomain

public struct MealLogHomeView: View {
    @ObservedObject private var viewModel: MealLogListViewModel
    private let campusMenuRepository: any CampusMenuRepository
    @State private var showingAddSheet = false
    @State private var editingLog: MealLog?

    public init(
        viewModel: MealLogListViewModel,
        campusMenuRepository: any CampusMenuRepository
    ) {
        self.viewModel = viewModel
        self.campusMenuRepository = campusMenuRepository
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.mealLogs.isEmpty {
                    ProgressView("正在加载饮食记录...")
                } else if viewModel.mealLogs.isEmpty {
                    ContentUnavailableView(
                        "还没有饮食记录",
                        systemImage: "fork.knife.circle",
                        description: Text("点击右上角“新增”，记录今天吃了什么。")
                    )
                } else {
                    List {
                        ForEach(viewModel.mealLogs) { log in
                            MealLogRowView(log: log)
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button("编辑") {
                                        editingLog = log
                                    }
                                    .tint(.blue)
                                }
                        }
                        .onDelete { offsets in
                            Task {
                                await viewModel.deleteLogs(at: offsets)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("吃什么？记录")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("新增", systemImage: "plus")
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                AddMealLogSheetView(
                    menuRepository: campusMenuRepository,
                    onCancel: { showingAddSheet = false },
                    onSave: { input in
                        let success = await viewModel.addLog(input: input)
                        if success {
                            showingAddSheet = false
                        }
                        return success
                    }
                )
            }
        }
        .sheet(item: $editingLog) { log in
            NavigationStack {
                EditMealLogSheetView(
                    log: log,
                    onCancel: { editingLog = nil },
                    onSave: { input in
                        let success = await viewModel.updateLog(id: log.id, input: input)
                        if success {
                            editingLog = nil
                        }
                        return success
                    }
                )
            }
        }
        .alert(
            "操作失败",
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
}

private struct MealLogRowView: View {
    let log: MealLog

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(log.mealType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                Text(Self.dateFormatter.string(from: log.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(log.dishName)
                .font(.headline)

            HStack {
                Text(log.storeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let price = log.price {
                    Text("¥\(price, specifier: "%.0f")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MealLogFormDraft {
    var selectedMealType: MealType
    var date: Date
    var storeId: UUID?
    var dishId: UUID?
    var storeName: String
    var dishName: String
    var priceText: String
    var nutrition: NutrientSnapshot?
}

private struct AddMealLogSheetView: View {
    let onCancel: () -> Void
    let onSave: (NewMealLogInput) async -> Bool

    @StateObject private var draftViewModel: AddMealLogDraftViewModel
    @State private var selectedMealType: MealType
    @State private var date: Date
    @State private var isMealTypeAutoControlled = true
    @State private var isSaving = false
    @State private var localError: String?

    private let mealTypeResolver: AutoMealTypeResolver

    init(
        menuRepository: any CampusMenuRepository,
        onCancel: @escaping () -> Void,
        onSave: @escaping (NewMealLogInput) async -> Bool
    ) {
        self.onCancel = onCancel
        self.onSave = onSave

        let resolver = AutoMealTypeResolver()
        let now = Date()
        _selectedMealType = State(initialValue: resolver.resolve(date: now))
        _date = State(initialValue: now)
        _draftViewModel = StateObject(
            wrappedValue: AddMealLogDraftViewModel(menuRepository: menuRepository)
        )
        mealTypeResolver = resolver
    }

    var body: some View {
        Form {
            Section("地图选店铺") {
                AddMealLogMapSection(
                    stores: draftViewModel.stores,
                    selectedStoreID: draftViewModel.selectedStore?.id,
                    mapCenter: draftViewModel.mapCenter,
                    campusBounds: .nuist,
                    onMapCenterChange: { center in
                        draftViewModel.updateMapCenter(center)
                    },
                    onLocationUpdate: { point in
                        draftViewModel.updateUserLocation(point)
                    }
                )
                .frame(height: 210)

                Text(draftViewModel.locationHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let lastAutoSelectedStoreName = draftViewModel.lastAutoSelectedStoreName {
                    Text("最近店铺：\(lastAutoSelectedStoreName)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.blue)
                }

                if let vmError = draftViewModel.errorMessage {
                    Text(vmError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("基础信息") {
                DatePicker("时间", selection: $date)
                Picker("餐次", selection: Binding(
                    get: { selectedMealType },
                    set: { newValue in
                        selectedMealType = newValue
                        isMealTypeAutoControlled = false
                    }
                )) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Text(mealType.displayName).tag(mealType)
                    }
                }

                if !isMealTypeAutoControlled {
                    Button("按时间重置餐次") {
                        selectedMealType = mealTypeResolver.resolve(date: date)
                        isMealTypeAutoControlled = true
                    }
                    .font(.footnote)
                }
            }

            Section("店铺与菜品") {
                TextField("搜索店铺", text: $draftViewModel.storeSearchText)
                    .textInputAutocapitalization(.never)

                Picker("店铺", selection: Binding(
                    get: { draftViewModel.selectedStore?.id },
                    set: { storeID in
                        guard let storeID else { return }
                        draftViewModel.selectStoreManually(id: storeID)
                    }
                )) {
                    ForEach(draftViewModel.storePickerOptions) { store in
                        Text("\(store.name) · \(store.area)")
                            .tag(Optional(store.id))
                    }
                }

                if draftViewModel.isLoadingDishes {
                    ProgressView("正在同步菜品...")
                }

                Picker("菜品", selection: Binding(
                    get: { draftViewModel.dishSelection },
                    set: { selection in
                        draftViewModel.setDishSelection(selection)
                    }
                )) {
                    ForEach(draftViewModel.dishes) { dish in
                        Text(dish.name)
                            .tag(AddMealLogDraftViewModel.DishSelection.preset(dish.id))
                    }
                    Text("其他（手动填写）")
                        .tag(AddMealLogDraftViewModel.DishSelection.custom)
                }

                if draftViewModel.isUsingCustomDish {
                    TextField("输入菜品名", text: $draftViewModel.customDishName)
                }

                TextField("价格（自动填充，可修改）", text: $draftViewModel.priceText)
                    .keyboardType(.decimalPad)
            }

            Section("营养估算") {
                if let nutrition = draftViewModel.selectedNutrition {
                    NutrientGrid(nutrition: nutrition)
                } else {
                    Text("当前菜品暂无营养信息（自定义菜品保存后可补录）。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let localError {
                Section {
                    Text(localError)
                        .foregroundStyle(.red)
                }
            }

        }
        .navigationTitle("新增记录")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    onCancel()
                }
                .disabled(isSaving)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    Task {
                        await save()
                    }
                }
                .disabled(isSaving || draftViewModel.isLoadingStores)
            }
        }
        .task {
            await draftViewModel.load()
        }
        .onChange(of: date, initial: false) { _, newValue in
            guard isMealTypeAutoControlled else { return }
            selectedMealType = mealTypeResolver.resolve(date: newValue)
        }
    }

    private func save() async {
        localError = nil
        draftViewModel.clearError()

        isSaving = true
        defer { isSaving = false }

        do {
            let input = try draftViewModel.makeInput(date: date, mealType: selectedMealType)
            let success = await onSave(input)
            if !success {
                localError = "保存失败，请稍后重试。"
            }
        } catch {
            localError = error.localizedDescription
        }
    }
}

private struct NutrientGrid: View {
    let nutrition: NutrientSnapshot

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                NutrientMetricItem(title: "能量", value: "\(formatted(nutrition.caloriesKcal)) kcal")
                NutrientMetricItem(title: "蛋白质", value: "\(formatted(nutrition.proteinG)) g")
                NutrientMetricItem(title: "脂肪", value: "\(formatted(nutrition.fatG)) g")
            }
            HStack(spacing: 12) {
                NutrientMetricItem(title: "碳水", value: "\(formatted(nutrition.carbG)) g")
                NutrientMetricItem(title: "钠", value: "\(formatted(nutrition.sodiumMg)) mg")
                NutrientMetricItem(title: "纤维", value: "\(formatted(nutrition.fiberG)) g")
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.0f", value)
    }
}

private struct NutrientMetricItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EditMealLogSheetView: View {
    let log: MealLog
    let onCancel: () -> Void
    let onSave: (NewMealLogInput) async -> Bool

    var body: some View {
        MealLogEditorFormView(
            title: "编辑记录",
            saveButtonTitle: "更新",
            initialDraft: MealLogFormDraft(
                selectedMealType: log.mealType,
                date: log.date,
                storeId: log.storeId,
                dishId: log.dishId,
                storeName: log.storeName,
                dishName: log.dishName,
                priceText: Self.priceText(from: log.price),
                nutrition: log.nutrition
            ),
            onCancel: onCancel,
            onSave: onSave
        )
    }

    private static func priceText(from price: Double?) -> String {
        guard let price else { return "" }
        return String(format: "%.2f", price).replacingOccurrences(of: ".00", with: "")
    }
}

private struct MealLogEditorFormView: View {
    let title: String
    let saveButtonTitle: String
    let onCancel: () -> Void
    let onSave: (NewMealLogInput) async -> Bool

    @State private var selectedMealType: MealType
    @State private var date: Date
    @State private var storeName: String
    @State private var dishName: String
    @State private var priceText: String
    @State private var isSaving = false
    @State private var localError: String?

    private let originalStoreName: String
    private let originalDishName: String
    private let originalStoreID: UUID?
    private let originalDishID: UUID?
    private let originalNutrition: NutrientSnapshot?

    init(
        title: String,
        saveButtonTitle: String,
        initialDraft: MealLogFormDraft,
        onCancel: @escaping () -> Void,
        onSave: @escaping (NewMealLogInput) async -> Bool
    ) {
        self.title = title
        self.saveButtonTitle = saveButtonTitle
        self.onCancel = onCancel
        self.onSave = onSave
        _selectedMealType = State(initialValue: initialDraft.selectedMealType)
        _date = State(initialValue: initialDraft.date)
        _storeName = State(initialValue: initialDraft.storeName)
        _dishName = State(initialValue: initialDraft.dishName)
        _priceText = State(initialValue: initialDraft.priceText)
        originalStoreName = initialDraft.storeName
        originalDishName = initialDraft.dishName
        originalStoreID = initialDraft.storeId
        originalDishID = initialDraft.dishId
        originalNutrition = initialDraft.nutrition
    }

    var body: some View {
        Form {
            Section("基础信息") {
                Picker("餐次", selection: $selectedMealType) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Text(mealType.displayName).tag(mealType)
                    }
                }
                DatePicker("时间", selection: $date)
            }

            Section("饮食内容") {
                TextField("店铺名（例如：一食堂米线档）", text: $storeName)
                TextField("菜品名（例如：番茄牛肉米线）", text: $dishName)
                TextField("价格（可选）", text: $priceText)
                    .keyboardType(.decimalPad)
            }

            if let localError {
                Section {
                    Text(localError)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    onCancel()
                }
                .disabled(isSaving)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(saveButtonTitle) {
                    Task {
                        await save()
                    }
                }
                .disabled(isSaving)
            }
        }
    }

    private func save() async {
        localError = nil
        let trimmedStore = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDish = dishName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedStore.isEmpty, !trimmedDish.isEmpty else {
            localError = "请填写店铺名和菜品名。"
            return
        }

        let parsedPrice: Double?
        let trimmedPrice = priceText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPrice.isEmpty {
            parsedPrice = nil
        } else if let number = Double(trimmedPrice), number >= 0 {
            parsedPrice = number
        } else {
            localError = "价格格式无效，请输入非负数字。"
            return
        }

        let isStoreUnchanged = trimmedStore == originalStoreName.trimmingCharacters(in: .whitespacesAndNewlines)
        let isDishUnchanged = trimmedDish == originalDishName.trimmingCharacters(in: .whitespacesAndNewlines)

        isSaving = true
        defer { isSaving = false }

        let input = NewMealLogInput(
            date: date,
            mealType: selectedMealType,
            storeId: isStoreUnchanged ? originalStoreID : nil,
            dishId: (isStoreUnchanged && isDishUnchanged) ? originalDishID : nil,
            storeName: trimmedStore,
            dishName: trimmedDish,
            price: parsedPrice,
            nutrition: (isStoreUnchanged && isDishUnchanged) ? originalNutrition : nil
        )
        _ = await onSave(input)
    }
}
