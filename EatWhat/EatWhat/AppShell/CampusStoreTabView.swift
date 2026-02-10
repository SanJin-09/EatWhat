import SwiftUI
import CoreLocation
import MapKit
import CoreDomain
import FeatureCampusStore

@MainActor
struct CampusStoreTabView: View {
    @ObservedObject private var viewModel: CampusStoreMapViewModel
    @State private var isCampusDetailPresented = false

    init(viewModel: CampusStoreMapViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapSection
                .ignoresSafeArea(edges: .all)
            topOverlayContainer
                .safeAreaPadding(.top, 10)
        }
        .sheet(item: $viewModel.selectedMarker, onDismiss: {
            viewModel.clearSelection()
        }) { marker in
            StoreMarkerSheet(marker: marker, viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.loadStoresIfNeeded()
        }
    }

    private var topOverlayContainer: some View {
        VStack(spacing: 8) {
            campusTopOverlay

            if viewModel.isLoadingStores {
                ProgressView("正在同步店铺数据...")
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .onTapGesture {
                        viewModel.clearError()
                        Task {
                            await viewModel.loadStoresIfNeeded()
                        }
                    }
            }

            if viewModel.hiddenCanteenCount > 0 {
                Text("有 \(viewModel.hiddenCanteenCount) 个食堂缺少坐标，已在地图隐藏。")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
            }
        }
    }

    private var campusTopOverlay: some View {
        Button {
            isCampusDetailPresented = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "building.columns.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Text(":")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                HStack(spacing: 4) {
                    Text("南京信息工程大学")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.clear)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.regularMaterial)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22))
            }
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isCampusDetailPresented) {
            CampusDetailSheet()
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var mapSection: some View {
        ZStack(alignment: .top) {
            MapKitCampusStoreMapSection(
                markers: viewModel.markers,
                boundary: viewModel.campusBoundary,
                center: viewModel.campusCenter,
                onSelectMarker: { marker in
                    viewModel.selectedMarker = marker
                },
                onLocationUpdate: { point in
                    viewModel.updateUserLocation(point)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let message = viewModel.mapEmptyMessage, !viewModel.isLoadingStores {
                EmptyStateCard(
                    systemImage: "mappin.slash",
                    title: "地图暂无点位",
                    message: message,
                    actionTitle: nil,
                    action: nil
                )
                .padding(.horizontal, 20)
                .padding(.top, 84)
            }
        }
    }
}

private struct StoreMarkerSheet: View {
    let marker: CampusStoreMarker
    @ObservedObject var viewModel: CampusStoreMapViewModel

    var body: some View {
        NavigationStack {
            switch marker.kind {
            case .canteen:
                if let canteenId = marker.canteenId {
                    CanteenOverviewPage(canteenId: canteenId, viewModel: viewModel)
                } else {
                    PlaceholderSheetPage(
                        title: "食堂信息",
                        message: "当前食堂标点信息不完整，请稍后重试。"
                    )
                }
            case .outdoorStore:
                if let storeId = marker.storeId {
                    StoreDetailPage(
                        storeId: storeId,
                        sourceTitle: "独立店铺",
                        viewModel: viewModel
                    )
                } else {
                    PlaceholderSheetPage(
                        title: "店铺信息",
                        message: "当前店铺标点信息不完整，请稍后重试。"
                    )
                }
            }
        }
    }
}

private struct CanteenOverviewPage: View {
    let canteenId: UUID
    @ObservedObject var viewModel: CampusStoreMapViewModel

    var body: some View {
        Group {
            if let canteen = viewModel.canteen(for: canteenId) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SheetInfoCard(title: "基础信息") {
                            InfoRow(title: "食堂名称", value: canteen.name)
                            InfoRow(title: "坐标", value: coordinateText(canteen.coordinate))
                            InfoRow(title: "楼层数量", value: "\(canteen.floors.count) 层")
                            InfoRow(title: "楼层覆盖", value: floorCoverageText(canteen))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("楼层列表")
                                .font(.headline)

                            if canteen.floors.isEmpty {
                                EmptyStateCard(
                                    systemImage: "building.2.crop.circle",
                                    title: "暂无楼层数据",
                                    message: "该食堂暂未配置楼层信息。",
                                    actionTitle: nil,
                                    action: nil
                                )
                            } else {
                                ForEach(canteen.floors.sorted(by: floorSort)) { floor in
                                    NavigationLink {
                                        CanteenFloorPage(
                                            canteenId: canteen.id,
                                            floorId: floor.id,
                                            viewModel: viewModel
                                        )
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(floor.floorLabel)
                                                    .font(.headline)
                                                    .foregroundStyle(.primary)
                                                Text("\(floor.stores.count) 家店铺")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer(minLength: 0)

                                            Image(systemName: "chevron.right")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(Color(uiColor: .secondarySystemBackground))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .navigationTitle(canteen.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                PlaceholderSheetPage(
                    title: "食堂信息",
                    message: "未能读取该食堂数据，请返回地图后重试。"
                )
            }
        }
    }

    private func coordinateText(_ coordinate: CampusCoordinate?) -> String {
        guard let coordinate else {
            return "暂无数据"
        }
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }

    private func floorCoverageText(_ canteen: CampusCanteenOption) -> String {
        let totalFloors = canteen.floors.count
        let floorsWithStores = canteen.floors.filter { !$0.stores.isEmpty }.count
        return "\(floorsWithStores)/\(totalFloors) 楼层已有店铺"
    }

    private func floorSort(lhs: CampusCanteenFloorOption, rhs: CampusCanteenFloorOption) -> Bool {
        if lhs.floorOrder != rhs.floorOrder {
            return lhs.floorOrder < rhs.floorOrder
        }
        return lhs.floorLabel.localizedCompare(rhs.floorLabel) == .orderedAscending
    }
}

private struct CanteenFloorPage: View {
    let canteenId: UUID
    let floorId: UUID
    @ObservedObject var viewModel: CampusStoreMapViewModel

    var body: some View {
        Group {
            if let canteen = viewModel.canteen(for: canteenId),
               let floor = viewModel.floor(canteenId: canteenId, floorId: floorId) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        SheetInfoCard(title: "楼层信息") {
                            InfoRow(title: "食堂", value: canteen.name)
                            InfoRow(title: "楼层", value: floor.floorLabel)
                            InfoRow(title: "店铺数", value: "\(floor.stores.count) 家")
                        }

                        Text("店铺列表")
                            .font(.headline)

                        if floor.stores.isEmpty {
                            EmptyStateCard(
                                systemImage: "storefront",
                                title: "该楼层暂无店铺",
                                message: "数据库中尚未配置该楼层店铺，请稍后再试。",
                                actionTitle: nil,
                                action: nil
                            )
                        } else {
                            ForEach(floor.stores) { store in
                                NavigationLink {
                                    StoreDetailPage(
                                        storeId: store.id,
                                        sourceTitle: "\(canteen.name) · \(floor.floorLabel)",
                                        viewModel: viewModel
                                    )
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(store.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text(store.area)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer(minLength: 0)

                                        Image(systemName: "chevron.right")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color(uiColor: .secondarySystemBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .navigationTitle("\(floor.floorLabel) 店铺")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                PlaceholderSheetPage(
                    title: "楼层信息",
                    message: "当前楼层数据不可用，请返回上一页重试。"
                )
            }
        }
    }
}

private struct StoreDetailPage: View {
    let storeId: UUID
    let sourceTitle: String
    @ObservedObject var viewModel: CampusStoreMapViewModel

    var body: some View {
        Group {
            if let store = viewModel.store(storeId: storeId) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SheetInfoCard(title: "店铺信息") {
                            InfoRow(title: "店铺名称", value: store.name)
                            InfoRow(title: "所属区域", value: store.area)
                            InfoRow(title: "来源", value: sourceTitle)
                            InfoRow(
                                title: "坐标",
                                value: String(format: "%.6f, %.6f", store.coordinate.latitude, store.coordinate.longitude)
                            )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("菜品列表")
                                .font(.headline)

                            switch viewModel.dishState(for: store.id) {
                            case .idle, .loading:
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("正在加载菜品...")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(uiColor: .secondarySystemBackground))
                                )

                            case .failed(let message):
                                EmptyStateCard(
                                    systemImage: "exclamationmark.triangle",
                                    title: "菜品加载失败",
                                    message: message,
                                    actionTitle: "重试"
                                ) {
                                    Task {
                                        await viewModel.retryDishes(for: store.id)
                                    }
                                }

                            case .empty:
                                EmptyStateCard(
                                    systemImage: "fork.knife.circle",
                                    title: "暂无菜品数据",
                                    message: "该店铺当前没有可展示的菜品信息。",
                                    actionTitle: nil,
                                    action: nil
                                )

                            case .loaded(let dishes):
                                ForEach(dishes) { dish in
                                    DishRow(dish: dish)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .navigationTitle(store.name)
                .navigationBarTitleDisplayMode(.inline)
                .task(id: store.id) {
                    await viewModel.loadDishesIfNeeded(storeId: store.id)
                }
            } else {
                PlaceholderSheetPage(
                    title: "店铺详情",
                    message: "未能读取该店铺信息，请返回上一页重试。"
                )
            }
        }
    }
}

private struct DishRow: View {
    let dish: CampusDishOption

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dish.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(nutritionSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(priceText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var priceText: String {
        guard let price = dish.price else {
            return "--"
        }

        if price.rounded() == price {
            return "¥\(Int(price))"
        }
        return String(format: "¥%.1f", price)
    }

    private var nutritionSummary: String {
        guard let nutrition = dish.nutrition else {
            return "营养信息暂无"
        }

        let calories = Int(nutrition.caloriesKcal.rounded())
        return String(
            format: "%d kcal · 蛋白%.1fg · 脂肪%.1fg · 碳水%.1fg",
            calories,
            nutrition.proteinG,
            nutrition.fatG,
            nutrition.carbG
        )
    }
}

private struct PlaceholderSheetPage: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            EmptyStateCard(
                systemImage: "questionmark.app",
                title: title,
                message: message,
                actionTitle: nil,
                action: nil
            )
            Spacer(minLength: 0)
        }
        .padding(16)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SheetInfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value.isEmpty ? "暂无数据" : value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.primary)
        }
    }
}

private struct EmptyStateCard: View {
    let systemImage: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

private struct CampusDetailSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule()
                .fill(.tertiary)
                .frame(width: 42, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "building.columns.fill")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("南京信息工程大学")
                        .font(.title3.weight(.semibold))
                    Text("EatWhat 当前校区信息")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 10) {
                CampusDetailRow(
                    symbol: "map.fill",
                    title: "地图点位",
                    detail: "蓝色为食堂，橙色为独立店铺。"
                )
                CampusDetailRow(
                    symbol: "location.fill",
                    title: "定位说明",
                    detail: "用于判断是否在校区内，提升推荐准确度。"
                )
                CampusDetailRow(
                    symbol: "list.bullet.rectangle",
                    title: "分层导航",
                    detail: "食堂支持楼层与店铺分级浏览。"
                )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

private struct CampusDetailRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

private extension GeoPoint {
    var coordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension CLLocationCoordinate2D {
    var geoPoint: GeoPoint {
        GeoPoint(latitude: latitude, longitude: longitude)
    }
}

private extension CampusBoundary {
    var rectangularOverlayCoordinates: [CLLocationCoordinate2D] {
        [
            CLLocationCoordinate2D(latitude: maxLatitude, longitude: minLongitude),
            CLLocationCoordinate2D(latitude: maxLatitude, longitude: maxLongitude),
            CLLocationCoordinate2D(latitude: minLatitude, longitude: maxLongitude),
            CLLocationCoordinate2D(latitude: minLatitude, longitude: minLongitude)
        ]
    }
}

private struct MapKitCampusStoreMapSection: UIViewRepresentable {
    let markers: [CampusStoreMarker]
    let boundary: CampusBoundary
    let center: GeoPoint
    let onSelectMarker: (CampusStoreMarker?) -> Void
    let onLocationUpdate: (GeoPoint?) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = true
        mapView.showsBuildings = false
        mapView.pointOfInterestFilter = .excludingAll

        let region = MKCoordinateRegion(
            center: center.coordinate2D,
            span: MKCoordinateSpan(latitudeDelta: 0.020, longitudeDelta: 0.020)
        )
        mapView.setRegion(region, animated: false)

        context.coordinator.installBoundaryOverlay(on: mapView, boundary: boundary)
        context.coordinator.installMarkers(on: mapView, markers: markers)
        context.coordinator.requestWhenInUseAuthorization()
        context.coordinator.startLocationUpdates()
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.updateParent(self)
        context.coordinator.syncBoundaryOverlay(on: mapView, boundary: boundary)
        context.coordinator.syncMarkers(on: mapView, markers: markers)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private var parent: MapKitCampusStoreMapSection
        private let locationManager = CLLocationManager()
        private var annotationsByID: [String: CampusStoreMarkerAnnotation] = [:]
        private var boundaryOverlay: MKPolygon?
        private var renderedBoundary: CampusBoundary?
        private var isRecentering = false

        init(parent: MapKitCampusStoreMapSection) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }

        func updateParent(_ parent: MapKitCampusStoreMapSection) {
            self.parent = parent
        }

        func installBoundaryOverlay(on mapView: MKMapView, boundary: CampusBoundary) {
            if let boundaryOverlay {
                mapView.removeOverlay(boundaryOverlay)
            }

            var coordinates = overlayCoordinates(for: boundary)
            let overlay = MKPolygon(coordinates: &coordinates, count: coordinates.count)
            mapView.addOverlay(overlay)
            boundaryOverlay = overlay
            renderedBoundary = boundary
        }

        func syncBoundaryOverlay(on mapView: MKMapView, boundary: CampusBoundary) {
            guard renderedBoundary != boundary else { return }
            installBoundaryOverlay(on: mapView, boundary: boundary)
        }

        private func overlayCoordinates(for boundary: CampusBoundary) -> [CLLocationCoordinate2D] {
            if boundary == NUISTCampusRegion.boundary {
                return NUISTCampusRegion.outline.map(\.coordinate2D)
            }
            return boundary.rectangularOverlayCoordinates
        }

        func installMarkers(on mapView: MKMapView, markers: [CampusStoreMarker]) {
            let annotations = markers.map(CampusStoreMarkerAnnotation.init)
            annotationsByID = Dictionary(uniqueKeysWithValues: annotations.map { ($0.marker.id, $0) })
            mapView.addAnnotations(annotations)
        }

        func syncMarkers(on mapView: MKMapView, markers: [CampusStoreMarker]) {
            let targetIDs = Set(markers.map(\.id))
            let currentIDs = Set(annotationsByID.keys)
            let removedIDs = currentIDs.subtracting(targetIDs)
            let addedMarkers = markers.filter { !currentIDs.contains($0.id) }
            let changedMarkers = markers.filter {
                guard let existing = annotationsByID[$0.id] else { return false }
                return existing.marker != $0
            }

            if !removedIDs.isEmpty {
                let removedAnnotations = removedIDs.compactMap { annotationsByID.removeValue(forKey: $0) }
                mapView.removeAnnotations(removedAnnotations)
            }

            if !addedMarkers.isEmpty {
                let addedAnnotations = addedMarkers.map(CampusStoreMarkerAnnotation.init)
                for annotation in addedAnnotations {
                    annotationsByID[annotation.marker.id] = annotation
                }
                mapView.addAnnotations(addedAnnotations)
            }

            if !changedMarkers.isEmpty {
                let oldAnnotations = changedMarkers.compactMap { annotationsByID[$0.id] }
                mapView.removeAnnotations(oldAnnotations)

                let refreshedAnnotations = changedMarkers.map(CampusStoreMarkerAnnotation.init)
                for annotation in refreshedAnnotations {
                    annotationsByID[annotation.marker.id] = annotation
                }
                mapView.addAnnotations(refreshedAnnotations)
            }
        }

        func requestWhenInUseAuthorization() {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        }

        func startLocationUpdates() {
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.requestLocation()
                locationManager.startUpdatingLocation()
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            default:
                parent.onLocationUpdate(nil)
            }
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            startLocationUpdates()
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let coordinate = locations.last?.coordinate else { return }
            parent.onLocationUpdate(coordinate.geoPoint)
            manager.stopUpdatingLocation()
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
            parent.onLocationUpdate(nil)
            manager.stopUpdatingLocation()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            guard let markerAnnotation = annotation as? CampusStoreMarkerAnnotation else { return nil }

            let identifier = "CampusStoreMarkerPin"
            let view: MKMarkerAnnotationView
            if let reused = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                view = reused
                view.annotation = annotation
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }

            view.canShowCallout = true

            switch markerAnnotation.marker.kind {
            case .canteen:
                view.markerTintColor = .systemBlue
                view.glyphImage = UIImage(systemName: "building.2.fill")
            case .outdoorStore:
                view.markerTintColor = .systemOrange
                view.glyphImage = UIImage(systemName: "fork.knife")
            }

            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            guard let polygon = overlay as? MKPolygon else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = UIColor.systemBlue
            renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.10)
            renderer.lineWidth = 2
            renderer.lineDashPattern = [7, 5]
            return renderer
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? CampusStoreMarkerAnnotation else { return }
            parent.onSelectMarker(annotation.marker)
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard view.annotation is CampusStoreMarkerAnnotation else { return }
            parent.onSelectMarker(nil)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard !isRecentering else { return }
            let center = mapView.centerCoordinate.geoPoint
            let clamped = parent.boundary.clamped(center)
            guard clamped != center else { return }

            isRecentering = true
            mapView.setCenter(clamped.coordinate2D, animated: true)
            DispatchQueue.main.async { [weak self] in
                self?.isRecentering = false
            }
        }
    }
}

private final class CampusStoreMarkerAnnotation: NSObject, MKAnnotation {
    let marker: CampusStoreMarker
    dynamic var coordinate: CLLocationCoordinate2D

    var title: String? {
        marker.title
    }

    var subtitle: String? {
        marker.subtitle
    }

    init(marker: CampusStoreMarker) {
        self.marker = marker
        self.coordinate = marker.coordinate.coordinate2D
        super.init()
    }
}
