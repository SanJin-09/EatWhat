#if os(iOS)
import SwiftUI
import CoreLocation
import MapKit

public struct CampusStoreHomeView: View {
    @ObservedObject private var viewModel: CampusStoreMapViewModel

    public init(viewModel: CampusStoreMapViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mapSection
                Divider()
                infoSection
            }
            .navigationTitle("校内店铺")
        }
    }

    @ViewBuilder
    private var mapSection: some View {
        MapKitCampusStoreMapView(
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

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("地图范围：南京信息工程大学")
                .font(.headline)
            Text(viewModel.locationHint)
                .font(.subheadline)
                .foregroundStyle(viewModel.isUserInsideCampus ? .green : .secondary)

            if let selected = viewModel.selectedStore {
                StoreSummaryCard(store: selected)
            } else {
                Text("点击地图上的店铺标注可查看详情。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

private struct StoreSummaryCard: View {
    let store: CampusStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(store.name)
                .font(.headline)
            Text(store.area)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("推荐：\(store.dishHint)")
                .font(.subheadline)
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

private struct MapKitCampusStoreMapView: UIViewRepresentable {
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
        private var parent: MapKitCampusStoreMapView
        private let locationManager = CLLocationManager()
        private var annotationsByID: [UUID: CampusStoreAnnotation] = [:]
        private var isRecentering = false

        init(parent: MapKitCampusStoreMapView) {
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

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            parent.onSelectStore(nil)
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
#endif
