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
            .task {
                await viewModel.loadStoresIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var mapSection: some View {
        MapKitCampusStoreMapView(
            markers: viewModel.markers,
            boundary: viewModel.campusBoundary,
            center: viewModel.campusCenter,
            onSelectMarker: { selected in
                viewModel.selectedMarker = selected
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

            if let selected = viewModel.selectedMarker {
                MarkerSummaryCard(marker: selected)
            } else {
                Text("点击地图上的标注可查看详情。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

private struct MarkerSummaryCard: View {
    let marker: CampusStoreMarker

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(marker.title)
                .font(.headline)

            Text(marker.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(marker.kind == .canteen ? "类型：食堂" : "类型：独立店铺")
                .font(.subheadline)
                .foregroundStyle(marker.kind == .canteen ? .blue : .orange)
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

private struct MapKitCampusStoreMapView: UIViewRepresentable {
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
        private var parent: MapKitCampusStoreMapView
        private let locationManager = CLLocationManager()
        private var annotationsByID: [String: CampusStoreMarkerAnnotation] = [:]
        private var boundaryOverlay: MKPolygon?
        private var renderedBoundary: CampusBoundary?
        private var isRecentering = false

        init(parent: MapKitCampusStoreMapView) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }

        func updateParent(_ parent: MapKitCampusStoreMapView) {
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

            let identifier = "CampusStorePin"
            let view: MKMarkerAnnotationView
            if let reused = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                view = reused
                view.annotation = annotation
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }

            view.canShowCallout = true
            view.markerTintColor = markerAnnotation.marker.kind == .canteen ? .systemBlue : .systemOrange
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
#endif
