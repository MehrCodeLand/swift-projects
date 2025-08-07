import UIKit
import CoreLocation
import MapKit

// MARK: - Tracking Point Model
struct TrackingPoint {
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let altitude: Double
    let speed: CLLocationSpeed
    let horizontalAccuracy: CLLocationAccuracy
    let verticalAccuracy: CLLocationAccuracy
    let satellites: Int?
}

// MARK: - Tracking Session Class
class TrackingSession {
    var points: [TrackingPoint] = []
    let startTime: Date
    var endTime: Date?
    
    init() {
        startTime = Date()
    }
    
    func addPoint(_ point: TrackingPoint) {
        points.append(point)
    }
    
    func endSession() {
        endTime = Date()
    }
}

// MARK: - Location Tracker
class LocationTracker: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var currentSession: TrackingSession?
    weak var delegate: LocationTrackerDelegate?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5 // Update every 5 meters
        
        // IMPORTANT: This requires that "location" is enabled in UIBackgroundModes in Info.plist.
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startTracking() {
        // Request always authorization; ensure Info.plist contains the necessary keys.
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        currentSession = TrackingSession()
    }
    
    func stopTracking() -> TrackingSession? {
        locationManager.stopUpdatingLocation()
        currentSession?.endSession()
        return currentSession
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let trackingPoint = TrackingPoint(
            coordinate: location.coordinate,
            timestamp: location.timestamp,
            altitude: location.altitude,
            speed: location.speed,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            satellites: nil
        )
        
        currentSession?.addPoint(trackingPoint)
        delegate?.didUpdateLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Handle changes in authorization status.
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location authorization granted.")
        case .denied, .restricted:
            print("Location authorization denied or restricted.")
        case .notDetermined:
            print("Location authorization not determined yet.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }
}

// MARK: - Location Tracker Delegate Protocol
protocol LocationTrackerDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocation)
}

// MARK: - GPX File Generator
class GPXFileGenerator {
    static func generateGPXFile(from session: TrackingSession) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var gpxContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="DriveTrackerApp">
        <metadata>
            <time>\(dateFormatter.string(from: session.startTime))</time>
        </metadata>
        <trk>
            <name>Track \(dateFormatter.string(from: session.startTime))</name>
            <trkseg>
        """
        
        for point in session.points {
            let pointXML = """
                <trkpt lat="\(point.coordinate.latitude)" lon="\(point.coordinate.longitude)">
                    <ele>\(point.altitude)</ele>
                    <time>\(dateFormatter.string(from: point.timestamp))</time>
                    <speed>\(point.speed)</speed>
                    <hdop>\(point.horizontalAccuracy)</hdop>
                    <vdop>\(point.verticalAccuracy)</vdop>
                </trkpt>
            """
            gpxContent += pointXML
        }
        
        gpxContent += """
            </trkseg>
        </trk>
        </gpx>
        """
        
        return gpxContent
    }
    
    static func saveGPXFile(content: String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "track_\(Date().timeIntervalSince1970).gpx"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving GPX file: \(error)")
            return nil
        }
    }
}

// MARK: - Main View Controller
class MainViewController: UIViewController, LocationTrackerDelegate, MKMapViewDelegate {
    private let locationTracker = LocationTracker()
    private var mapView: MKMapView!
    private var startButton: UIButton!
    private var stopButton: UIButton!
    private var shareButton: UIButton!
    private var trackingOverlay: MKPolyline?
    private var trackingCoordinates: [CLLocationCoordinate2D] = []
    
    // To store the GPX file URL for sharing.
    private var lastGPXFileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white  // Ensure proper background color
        setupLocationTracker()
        setupUI()
    }
    
    private func setupLocationTracker() {
        locationTracker.delegate = self
    }
    
    private func setupUI() {
        // MARK: MapView Setup
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = .standard
        view.addSubview(mapView)
        
        // MARK: Start Button Setup
        startButton = UIButton(type: .system)
        startButton.setTitle("Start Tracking", for: .normal)
        startButton.backgroundColor = .systemGreen
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(startTracking), for: .touchUpInside)
        view.addSubview(startButton)
        
        // MARK: Stop Button Setup
        stopButton = UIButton(type: .system)
        stopButton.setTitle("Stop Tracking", for: .normal)
        stopButton.backgroundColor = .systemRed
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 10
        stopButton.isEnabled = false
        stopButton.addTarget(self, action: #selector(stopTracking), for: .touchUpInside)
        view.addSubview(stopButton)
        
        // MARK: Share Button Setup
        shareButton = UIButton(type: .system)
        shareButton.setTitle("Share", for: .normal)
        shareButton.backgroundColor = .systemOrange
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.layer.cornerRadius = 10
        shareButton.addTarget(self, action: #selector(shareFile), for: .touchUpInside)
        shareButton.isHidden = true  // Initially hidden
        view.addSubview(shareButton)
        
        // MARK: Layout Constraints
        mapView.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // MapView covers the entire view.
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Start Button at bottom left.
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startButton.widthAnchor.constraint(equalToConstant: 150),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Stop Button at bottom right.
            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stopButton.widthAnchor.constraint(equalToConstant: 150),
            stopButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Share Button centered above the start and stop buttons.
            shareButton.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -20),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 150),
            shareButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func startTracking() {
        // Update the start button to indicate an "Estimating" state.
        startButton.setTitle("Estimating", for: .normal)
        startButton.backgroundColor = .systemBlue  // Soft blue color
        // Disable the start button until the session is stopped.
        startButton.isEnabled = false
        // Hide the share button (if it was visible from a previous session).
        shareButton.isHidden = true
        // Start location tracking.
        locationTracker.startTracking()
        stopButton.isEnabled = true
        // Clear any previous route.
        trackingCoordinates.removeAll()
    }
    
    @objc private func stopTracking() {
        guard let session = locationTracker.stopTracking() else { return }
        
        let gpxContent = GPXFileGenerator.generateGPXFile(from: session)
        if let fileURL = GPXFileGenerator.saveGPXFile(content: gpxContent) {
            lastGPXFileURL = fileURL
            let alert = UIAlertController(
                title: "Tracking Completed",
                message: "GPX file saved at \(fileURL.lastPathComponent)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            // Show share button so user can share the file.
            shareButton.isHidden = false
        }
        
        // Reset the start button back to its initial state.
        startButton.setTitle("Start Tracking", for: .normal)
        startButton.backgroundColor = .systemGreen
        startButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    @objc private func shareFile() {
        guard let fileURL = lastGPXFileURL else { return }
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
    
    // MARK: - Location Tracker Delegate
    func didUpdateLocation(_ location: CLLocation) {
        // Update the map view region.
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        mapView.setRegion(region, animated: true)
        
        // Track coordinates for drawing the route.
        trackingCoordinates.append(location.coordinate)
        
        // Draw tracking route as a polyline.
        if trackingCoordinates.count > 1 {
            let polyline = MKPolyline(coordinates: trackingCoordinates, count: trackingCoordinates.count)
            if let existingOverlay = trackingOverlay {
                mapView.removeOverlay(existingOverlay)
            }
            mapView.addOverlay(polyline)
            trackingOverlay = polyline
        }
    }
    
    // MARK: - MapView Delegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer()
    }
}

// MARK: - App Delegate
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // Remove Scene Delegate configurations if not using one.
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let mainViewController = MainViewController()
        window?.rootViewController = mainViewController
        window?.makeKeyAndVisible()
        return true
    }
}
