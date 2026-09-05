import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    let events: [Event]
    let mapCenter: CLLocation?
    let radiusMiles: Double
    @Binding var selectedEvent: Event?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        mapView.pointOfInterestFilter = .excludingAll
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateRegion(mapView)
        updateAnnotations(mapView)
        updateRadiusOverlay(mapView)
        updateSelection(mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func updateRegion(_ mapView: MKMapView) {
        guard let location = mapCenter else { return }
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: radiusMiles * 1609.34 * 2,
            longitudinalMeters: radiusMiles * 1609.34 * 2
        )
        mapView.setRegion(region, animated: true)
    }

    private func updateAnnotations(_ mapView: MKMapView) {
        let currentAnnotations = mapView.annotations.compactMap { $0 as? EventAnnotation }
        let currentEventIDs = Set(currentAnnotations.map { $0.event.id })
        let newEventIDs = Set(events.map { $0.id })

        if currentEventIDs == newEventIDs {
            return
        }

        let annotationsToRemove = currentAnnotations.filter { !newEventIDs.contains($0.event.id) }
        let eventsToAdd = events.filter { !currentEventIDs.contains($0.id) }

        mapView.removeAnnotations(annotationsToRemove)

        let newAnnotations = eventsToAdd.map { event in
            EventAnnotation(event: event)
        }
        mapView.addAnnotations(newAnnotations)
    }

    private func updateRadiusOverlay(_ mapView: MKMapView) {
        mapView.overlays.forEach { overlay in
            if overlay is MKCircle {
                mapView.removeOverlay(overlay)
            }
        }
        guard let location = mapCenter else { return }
        let circle = MKCircle(center: location.coordinate, radius: radiusMiles * 1609.34)
        mapView.addOverlay(circle)
    }

    private func updateSelection(_ mapView: MKMapView) {
        if let selectedEvent = selectedEvent {
            if let annotation = mapView.annotations.first(where: { ($0 as? EventAnnotation)?.event.id == selectedEvent.id }) {
                if !mapView.selectedAnnotations.contains(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) {
                    mapView.selectAnnotation(annotation, animated: true)
                }
            }
        } else {
            mapView.selectedAnnotations.forEach { annotation in
                if annotation is EventAnnotation {
                    mapView.deselectAnnotation(annotation, animated: true)
                }
            }
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5)
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            let identifier = "EventAnnotationView"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true

                let button = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = button
            } else {
                annotationView?.annotation = annotation
            }

            if let eventAnnotation = annotation as? EventAnnotation {
                switch eventAnnotation.event.gameType {
                case .trivia:
                    annotationView?.markerTintColor = .systemPurple
                    annotationView?.glyphImage = UIImage(systemName: "questionmark.circle.fill")
                case .musicBingo:
                    annotationView?.markerTintColor = .systemOrange
                    annotationView?.glyphImage = UIImage(systemName: "music.note.list")
                case .karaoke:
                    annotationView?.markerTintColor = .systemPink
                    annotationView?.glyphImage = UIImage(systemName: "mic.fill")
                case .themedNights:
                    annotationView?.markerTintColor = .systemBlue
                    annotationView?.glyphImage = UIImage(systemName: "star.fill")
                }
            }

            return annotationView
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let eventAnnotation = view.annotation as? EventAnnotation {
                parent.selectedEvent = eventAnnotation.event
            }
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let eventAnnotation = view.annotation as? EventAnnotation {
                parent.selectedEvent = eventAnnotation.event
            }
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if let eventAnnotation = view.annotation as? EventAnnotation {
                if parent.selectedEvent?.id == eventAnnotation.event.id {
                    parent.selectedEvent = nil
                }
            }
        }
    }
}

final class EventAnnotation: NSObject, MKAnnotation {
    let event: Event

    var coordinate: CLLocationCoordinate2D { event.coordinate }
    var title: String? { event.name }
    var subtitle: String? { event.venueName }

    init(event: Event) {
        self.event = event
        super.init()
    }
}
