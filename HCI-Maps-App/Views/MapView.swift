import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @Binding var selectedPlace: MKMapItem?
    @Binding var route: MKRoute?
    let transportType: MKDirectionsTransportType
    @Binding var mapRegion: MKCoordinateRegion
    @Binding var shouldFocusOnLocation: Bool
    @Binding var isTrackingUser: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Enable zoom and scroll
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        
        // Map type
        mapView.mapType = .standard
        
        // Enhanced user location display
        mapView.showsUserLocation = true
        mapView.userLocation.title = "My Location"
        mapView.userLocation.subtitle = "Current Position"
        
        // Add gesture recognizers for HCI interactions
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.mapTapped(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update tracking mode based on state
        if isTrackingUser && locationManager.location != nil {
            if mapView.userTrackingMode != .follow {
                mapView.setUserTrackingMode(.follow, animated: true)
            }
        } else {
            if mapView.userTrackingMode != .none {
                mapView.setUserTrackingMode(.none, animated: true)
            }
        }
        
        // Update map region when it changes (only if not tracking user)
        if !isTrackingUser {
            let currentRegion = mapView.region
            let newRegion = mapRegion
            
            // Only update if there's a significant change to avoid infinite loops
            if abs(currentRegion.center.latitude - newRegion.center.latitude) > 0.001 ||
               abs(currentRegion.center.longitude - newRegion.center.longitude) > 0.001 ||
               abs(currentRegion.span.latitudeDelta - newRegion.span.latitudeDelta) > 0.001 {
                mapView.setRegion(newRegion, animated: true)
            }
        }
        
        // Update selected place
        if let place = selectedPlace {
            // Remove existing annotations except user location
            let annotationsToRemove = mapView.annotations.filter { !($0 is MKUserLocation) }
            mapView.removeAnnotations(annotationsToRemove)
            
            // Add new annotation with enhanced appearance
            let annotation = CustomPointAnnotation(coordinate: place.placemark.coordinate)
            annotation.title = place.name
            annotation.subtitle = formatSubtitle(for: place)
            annotation.place = place
            mapView.addAnnotation(annotation)
        } else {
            // Remove all annotations except user location
            let annotationsToRemove = mapView.annotations.filter { !($0 is MKUserLocation) }
            mapView.removeAnnotations(annotationsToRemove)
        }
        
        // Remove any existing overlays (no more route display)
        mapView.removeOverlays(mapView.overlays)
    }
    
    private func formatSubtitle(for place: MKMapItem) -> String? {
        if let category = place.pointOfInterestCategory?.rawValue {
            return formatCategory(category)
        } else if isCity(place) {
            return "City"
        }
        return place.placemark.locality ?? place.placemark.administrativeArea
    }
    
    private func isCity(_ place: MKMapItem) -> Bool {
        let placemark = place.placemark
        return placemark.locality != nil &&
               place.pointOfInterestCategory == nil &&
               placemark.thoroughfare == nil
    }
    
    private func formatCategory(_ category: String) -> String {
        return category.replacingOccurrences(of: "MKPOICategory", with: "")
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func mapTapped(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Disable user tracking when user manually interacts with map
            parent.isTrackingUser = false
            
            // Reverse geocode to get place information
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                    DispatchQueue.main.async {
                        self.parent.selectedPlace = mapItem
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Disable user tracking when user manually changes region
            if parent.isTrackingUser && animated {
                parent.isTrackingUser = false
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Update the binding when user manually changes the region (only if not tracking)
            if !parent.isTrackingUser {
                DispatchQueue.main.async {
                    self.parent.mapRegion = mapView.region
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !annotation.isKind(of: MKUserLocation.self) else {
                // Customize user location view
                return createUserLocationView(for: annotation, in: mapView)
            }
            
            // Handle custom place annotations
            if let customAnnotation = annotation as? CustomPointAnnotation {
                return createCustomAnnotationView(for: customAnnotation, in: mapView)
            }
            
            // Default annotation
            let identifier = "PlaceAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize marker appearance for HCI
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = .red
                markerView.glyphImage = UIImage(systemName: "mappin.circle.fill")
                markerView.animatesWhenAdded = true
            }
            
            return annotationView
        }
        
        private func createUserLocationView(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
            let identifier = "UserLocation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // Create custom user location indicator
                let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                view.backgroundColor = .systemBlue
                view.layer.cornerRadius = 10
                view.layer.borderWidth = 3
                view.layer.borderColor = UIColor.white.cgColor
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOffset = CGSize(width: 0, height: 2)
                view.layer.shadowRadius = 3
                view.layer.shadowOpacity = 0.3
                
                // Add pulsing animation
                let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
                pulseAnimation.duration = 1.5
                pulseAnimation.fromValue = 1.0
                pulseAnimation.toValue = 1.3
                pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                pulseAnimation.autoreverses = true
                pulseAnimation.repeatCount = .infinity
                view.layer.add(pulseAnimation, forKey: "pulse")
                
                // Convert UIView to UIImage for annotation
                UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
                view.layer.render(in: UIGraphicsGetCurrentContext()!)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                annotationView?.image = image
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        private func createCustomAnnotationView(for annotation: CustomPointAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
            let identifier = "CustomPlace"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize based on place type
            if let place = annotation.place {
                if parent.isCity(place) {
                    annotationView?.markerTintColor = .systemPurple
                    annotationView?.glyphImage = UIImage(systemName: "building.2.crop.circle")
                } else {
                    annotationView?.markerTintColor = .systemRed
                    annotationView?.glyphImage = UIImage(systemName: getIconForPlace(place))
                }
            }
            
            annotationView?.animatesWhenAdded = true
            annotationView?.displayPriority = .required
            
            return annotationView
        }
        
        private func getIconForPlace(_ place: MKMapItem) -> String {
            guard let category = place.pointOfInterestCategory else {
                return "mappin.circle.fill"
            }
            
            switch category {
            case .restaurant, .foodMarket:
                return "fork.knife.circle.fill"
            case .gasStation:
                return "fuelpump.fill"
            case .hospital:
                return "cross.circle.fill"
            case .school, .university:
                return "graduationcap.fill"
            case .store:
                return "bag.circle.fill"
            case .bank:
                return "dollarsign.circle.fill"
            case .hotel:
                return "bed.double.circle.fill"
            case .parking:
                return "parkingsign.circle.fill"
            default:
                return "mappin.circle.fill"
            }
        }
    }
}

// Custom annotation class
class CustomPointAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var place: MKMapItem?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}




