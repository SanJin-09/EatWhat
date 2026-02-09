import SwiftUI
import CoreLocation
import MapKit
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
        .sheet(item: $viewModel.selectedStore, onDismiss: {
            viewModel.clearSelection()
        }) { store in
            StoreBottomSheet(
                store: store,
                locationHint: viewModel.locationHint,
                isUserInsideCampus: viewModel.isUserInsideCampus
            )
            .presentationDetents([.fraction(0.42)])
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
        MapKitCampusStoreMapSection(
            stores: viewModel.stores,
            boundary: viewModel.campusBoundary,
            center: viewModel.campusCenter,
            onSelectStore: { selected in
                viewModel.selectedStore = selected
            },
            onLocationUpdate: { point in
                viewModel.updateUserLocation(point)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StoreBottomSheet: View {
    let store: CampusStore
    let locationHint: String
    let isUserInsideCampus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(.tertiary)
                .frame(width: 42, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

            Text(store.name)
                .font(.title3.weight(.semibold))
            Text(store.area)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("推荐菜：\(store.dishHint)")
                .font(.body)

            Divider()

            Label("南京信息工程大学", systemImage: "building.2")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(locationHint)
                .font(.footnote)
                .foregroundStyle(isUserInsideCampus ? .green : .secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
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
                    title: "地图覆盖",
                    detail: "当前展示南信大及周边生活区店铺点位。"
                )
                CampusDetailRow(
                    symbol: "location.fill",
                    title: "定位说明",
                    detail: "用于判断是否在校区内，提升推荐准确度。"
                )
                CampusDetailRow(
                    symbol: "fork.knife",
                    title: "店铺数据",
                    detail: "店铺信息会随记录与评价持续更新。"
                )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
            )

            Text("提示：你可以在“店铺”页点击地图标注查看每家店的餐品与推荐信息。")
                .font(.footnote)
                .foregroundStyle(.secondary)

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

private struct MapKitCampusStoreMapSection: UIViewRepresentable {
    let stores: [CampusStore]
    let boundary: CampusBoundary
    let center: GeoPoint
    let onSelectStore: (CampusStore?) -> Void
    let onLocationUpdate: (GeoPoint?) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = true

        let region = MKCoordinateRegion(
            center: center.coordinate2D,
            span: MKCoordinateSpan(latitudeDelta: 0.020, longitudeDelta: 0.020)
        )
        mapView.setRegion(region, animated: false)

        context.coordinator.installStores(on: mapView, stores: stores)
        context.coordinator.requestWhenInUseAuthorization()
        context.coordinator.startLocationUpdates()
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.syncStores(on: mapView, stores: stores)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private var parent: MapKitCampusStoreMapSection
        private let locationManager = CLLocationManager()
        private var annotationsByID: [UUID: CampusStoreAnnotation] = [:]
        private var isRecentering = false

        init(parent: MapKitCampusStoreMapSection) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }

        func installStores(on mapView: MKMapView, stores: [CampusStore]) {
            let annotations = stores.map(CampusStoreAnnotation.init)
            annotationsByID = Dictionary(uniqueKeysWithValues: annotations.map { ($0.store.id, $0) })
            mapView.addAnnotations(annotations)
        }

        func syncStores(on mapView: MKMapView, stores: [CampusStore]) {
            let targetIDs = Set(stores.map(\.id))
            let currentIDs = Set(annotationsByID.keys)
            let removedIDs = currentIDs.subtracting(targetIDs)
            let addedStores = stores.filter { !currentIDs.contains($0.id) }
            let changedStores = stores.filter {
                guard let existing = annotationsByID[$0.id] else { return false }
                return existing.store != $0
            }

            if !removedIDs.isEmpty {
                let removedAnnotations = removedIDs.compactMap { annotationsByID.removeValue(forKey: $0) }
                mapView.removeAnnotations(removedAnnotations)
            }

            if !addedStores.isEmpty {
                let addedAnnotations = addedStores.map(CampusStoreAnnotation.init)
                for annotation in addedAnnotations {
                    annotationsByID[annotation.store.id] = annotation
                }
                mapView.addAnnotations(addedAnnotations)
            }

            if !changedStores.isEmpty {
                let oldAnnotations = changedStores.compactMap { annotationsByID[$0.id] }
                mapView.removeAnnotations(oldAnnotations)

                let refreshedAnnotations = changedStores.map(CampusStoreAnnotation.init)
                for annotation in refreshedAnnotations {
                    annotationsByID[annotation.store.id] = annotation
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

            let identifier = "CampusStorePin"
            let view: MKMarkerAnnotationView
            if let reused = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                view = reused
                view.annotation = annotation
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            view.canShowCallout = true
            view.markerTintColor = .systemPurple
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? CampusStoreAnnotation else { return }
            parent.onSelectStore(annotation.store)
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

private final class CampusStoreAnnotation: NSObject, MKAnnotation {
    let store: CampusStore
    dynamic var coordinate: CLLocationCoordinate2D

    var title: String? {
        store.name
    }

    var subtitle: String? {
        "\(store.area) · \(store.dishHint)"
    }

    init(store: CampusStore) {
        self.store = store
        self.coordinate = store.coordinate.coordinate2D
        super.init()
    }
}
