import SwiftUI
import CoreDomain

public struct MealLogHomeView: View {
    @ObservedObject private var viewModel: MealLogListViewModel
    @State private var showingAddSheet = false
    @State private var editingLog: MealLog?

    public init(viewModel: MealLogListViewModel) {
        self.viewModel = viewModel
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
    var storeName: String
    var dishName: String
    var priceText: String
}

private struct AddMealLogSheetView: View {
    let onCancel: () -> Void
    let onSave: (NewMealLogInput) async -> Bool

    var body: some View {
        MealLogEditorFormView(
            title: "新增记录",
            saveButtonTitle: "保存",
            initialDraft: MealLogFormDraft(
                selectedMealType: .lunch,
                date: Date(),
                storeName: "",
                dishName: "",
                priceText: ""
            ),
            onCancel: onCancel,
            onSave: onSave
        )
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
                storeName: log.storeName,
                dishName: log.dishName,
                priceText: Self.priceText(from: log.price)
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
        if priceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parsedPrice = nil
        } else if let number = Double(priceText), number >= 0 {
            parsedPrice = number
        } else {
            localError = "价格格式无效，请输入非负数字。"
            return
        }

        isSaving = true
        defer { isSaving = false }

        let input = NewMealLogInput(
            date: date,
            mealType: selectedMealType,
            storeName: trimmedStore,
            dishName: trimmedDish,
            price: parsedPrice
        )
        _ = await onSave(input)
    }
}
