import SwiftUI
import CoreLocation
import MapKit
import CoreDomain

struct AddMealLogMapSection: View {
    let stores: [CampusStoreOption]
    let selectedStoreID: UUID?
    let mapCenter: CampusCoordinate
    let campusBounds: CampusBounds
    let onMapCenterChange: (CampusCoordinate) -> Void
    let onLocationUpdate: (CampusCoordinate?) -> Void

    var body: some View {
        ZStack {
            AddMealLogMapViewRepresentable(
                stores: stores,
                selectedStoreID: selectedStoreID,
                center: mapCenter,
                campusBounds: campusBounds,
                onMapCenterChange: onMapCenterChange,
                onLocationUpdate: onLocationUpdate
            )

            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AddMealLogMapViewRepresentable: UIViewRepresentable {
    let stores: [CampusStoreOption]
    let selectedStoreID: UUID?
    let center: CampusCoordinate
    let campusBounds: CampusBounds
    let onMapCenterChange: (CampusCoordinate) -> Void
    let onLocationUpdate: (CampusCoordinate?) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.showsUserLocation = true
        mapView.pointOfInterestFilter = .includingAll

        let region = MKCoordinateRegion(
            center: center.coordinate2D,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
        mapView.setRegion(region, animated: false)

        context.coordinator.installStores(on: mapView, stores: stores)
        context.coordinator.startLocationServices()
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.update(parent: self)
        context.coordinator.syncStores(on: mapView, stores: stores)
        context.coordinator.syncCenter(on: mapView, targetCenter: center)
        context.coordinator.syncSelection(on: mapView, selectedStoreID: selectedStoreID)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private var parent: AddMealLogMapViewRepresentable
        private let locationManager = CLLocationManager()
        private var annotationsByStoreID: [UUID: StorePinAnnotation] = [:]
        private var isProgrammaticCenterChange = false

        init(parent: AddMealLogMapViewRepresentable) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }

        func update(parent: AddMealLogMapViewRepresentable) {
            self.parent = parent
        }

        func installStores(on mapView: MKMapView, stores: [CampusStoreOption]) {
            let annotations = stores.map(StorePinAnnotation.init)
            annotationsByStoreID = Dictionary(uniqueKeysWithValues: annotations.map { ($0.store.id, $0) })
            mapView.addAnnotations(annotations)
        }

        func syncStores(on mapView: MKMapView, stores: [CampusStoreOption]) {
            let newIDs = Set(stores.map(\.id))
            let existingIDs = Set(annotationsByStoreID.keys)

            let removed = existingIDs.subtracting(newIDs)
            if !removed.isEmpty {
                let removedAnnotations = removed.compactMap { annotationsByStoreID.removeValue(forKey: $0) }
                mapView.removeAnnotations(removedAnnotations)
            }

            let addedStores = stores.filter { !existingIDs.contains($0.id) }
            if !addedStores.isEmpty {
                let added = addedStores.map(StorePinAnnotation.init)
                for annotation in added {
                    annotationsByStoreID[annotation.store.id] = annotation
                }
                mapView.addAnnotations(added)
            }
        }

        func syncCenter(on mapView: MKMapView, targetCenter: CampusCoordinate) {
            let current = mapView.centerCoordinate
            let currentCoordinate = CampusCoordinate(latitude: current.latitude, longitude: current.longitude)
            let distance = CLLocation(
                latitude: currentCoordinate.latitude,
                longitude: currentCoordinate.longitude
            ).distance(from: CLLocation(latitude: targetCenter.latitude, longitude: targetCenter.longitude))

            // Avoid frequent recenter loops when user drags map or map emits tiny center drift.
            guard distance > 20 else { return }

            isProgrammaticCenterChange = true
            mapView.setCenter(targetCenter.coordinate2D, animated: false)
        }

        func syncSelection(on mapView: MKMapView, selectedStoreID: UUID?) {
            guard let selectedStoreID,
                  let annotation = annotationsByStoreID[selectedStoreID] else {
                mapView.selectedAnnotations = []
                return
            }

            if mapView.selectedAnnotations.contains(where: {
                ($0 as? StorePinAnnotation)?.store.id == selectedStoreID
            }) {
                return
            }

            mapView.selectAnnotation(annotation, animated: true)
        }

        func startLocationServices() {
            switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.requestLocation()
                locationManager.startUpdatingLocation()
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            default:
                parent.onLocationUpdate(nil)
            }
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            startLocationServices()
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let coordinate = locations.last?.coordinate else { return }
            parent.onLocationUpdate(CampusCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
            manager.stopUpdatingLocation()
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
            parent.onLocationUpdate(nil)
            manager.stopUpdatingLocation()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            let identifier = "MealLogStorePin"
            let marker: MKMarkerAnnotationView
            if let reused = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                marker = reused
                marker.annotation = annotation
            } else {
                marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }

            marker.canShowCallout = true
            marker.markerTintColor = .systemBlue
            return marker
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let currentCenter = CampusCoordinate(
                latitude: mapView.centerCoordinate.latitude,
                longitude: mapView.centerCoordinate.longitude
            )

            if isProgrammaticCenterChange {
                isProgrammaticCenterChange = false
                return
            }

            let clamped = parent.campusBounds.clamped(currentCenter)
            if clamped != currentCenter {
                isProgrammaticCenterChange = true
                mapView.setCenter(clamped.coordinate2D, animated: false)
            }

            parent.onMapCenterChange(clamped)
        }
    }
}

private final class StorePinAnnotation: NSObject, MKAnnotation {
    let store: CampusStoreOption
    dynamic var coordinate: CLLocationCoordinate2D

    var title: String? {
        store.name
    }

    var subtitle: String? {
        store.area
    }

    init(store: CampusStoreOption) {
        self.store = store
        self.coordinate = store.coordinate.coordinate2D
        super.init()
    }
}

private extension CampusCoordinate {
    var coordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
