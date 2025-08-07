import Foundation
import MapKit
import CoreLocation

// Enhanced Mock Route Helper Class
class MockRouteHelper {
    
    static func createRealisticRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) -> MockRouteResult {
        // Generate realistic waypoints with turns and road-like paths
        let waypoints = generateRealisticWaypoints(from: start, to: end, transportType: transportType)
        
        // Calculate total distance and travel time
        let distance = calculateTotalDistance(waypoints: waypoints)
        let travelTime = calculateTravelTime(distance: distance, transportType: transportType)
        
        // Create polyline for map display
        let polyline = MKPolyline(coordinates: waypoints, count: waypoints.count)
        
        // Generate turn-by-turn directions
        let directions = generateDirections(waypoints: waypoints, transportType: transportType)
        
        return MockRouteResult(
            polyline: polyline,
            distance: distance,
            expectedTravelTime: travelTime,
            directions: directions,
            waypoints: waypoints
        )
    }
    
    private static func generateRealisticWaypoints(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) -> [CLLocationCoordinate2D] {
        var waypoints: [CLLocationCoordinate2D] = [start]
        
        let latDiff = end.latitude - start.latitude
        let lonDiff = end.longitude - start.longitude
        let totalDistance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        
        // Determine number of segments based on distance and transport type
        let segmentDistance: Double = transportType == .walking ? 100 : 500 // meters per segment
        let numSegments = max(Int(totalDistance / segmentDistance), 8)
        
        // Create waypoints with realistic road-like curves
        for i in 1..<numSegments {
            let progress = Double(i) / Double(numSegments)
            
            // Add realistic deviations to simulate actual roads
            let roadDeviation = generateRoadDeviation(progress: progress, transportType: transportType, distance: totalDistance)
            
            let lat = start.latitude + (latDiff * progress) + roadDeviation.latitude
            let lon = start.longitude + (lonDiff * progress) + roadDeviation.longitude
            
            waypoints.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        waypoints.append(end)
        return waypoints
    }
    
    private static func generateRoadDeviation(progress: Double, transportType: MKDirectionsTransportType, distance: CLLocationDistance) -> CLLocationCoordinate2D {
        // Create realistic road curves and turns
        let maxDeviation: Double
        
        switch transportType {
        case .automobile:
            maxDeviation = min(0.002, distance / 1000000) // Larger roads, bigger curves
        case .walking:
            maxDeviation = min(0.0005, distance / 2000000) // Pedestrian paths, smaller deviations
        case .transit:
            maxDeviation = min(0.001, distance / 1500000) // Transit routes, moderate curves
        default:
            maxDeviation = 0.001
        }
        
        // Create sinusoidal curves to simulate road patterns
        let curve1 = sin(progress * .pi * 4) * maxDeviation * 0.6
        let curve2 = cos(progress * .pi * 3) * maxDeviation * 0.4
        let curve3 = sin(progress * .pi * 6) * maxDeviation * 0.2 // Smaller variations
        
        // Add some randomness for more realistic paths
        let randomLat = (Double.random(in: -1...1) * maxDeviation * 0.1)
        let randomLon = (Double.random(in: -1...1) * maxDeviation * 0.1)
        
        return CLLocationCoordinate2D(
            latitude: curve1 + curve3 + randomLat,
            longitude: curve2 - curve3 + randomLon
        )
    }
    
    private static func calculateTotalDistance(waypoints: [CLLocationCoordinate2D]) -> CLLocationDistance {
        var totalDistance: CLLocationDistance = 0
        
        for i in 0..<waypoints.count-1 {
            let location1 = CLLocation(latitude: waypoints[i].latitude, longitude: waypoints[i].longitude)
            let location2 = CLLocation(latitude: waypoints[i+1].latitude, longitude: waypoints[i+1].longitude)
            totalDistance += location1.distance(from: location2)
        }
        
        return totalDistance
    }
    
    private static func calculateTravelTime(distance: CLLocationDistance, transportType: MKDirectionsTransportType) -> TimeInterval {
        let kmDistance = distance / 1000.0
        
        switch transportType {
        case .automobile:
            // Average city driving speed: 30-50 km/h, highway: 80-100 km/h
            let avgSpeed = kmDistance > 10 ? 60.0 : 35.0 // km/h
            return (kmDistance / avgSpeed) * 3600 // Convert to seconds
            
        case .walking:
            // Average walking speed: 5 km/h
            return (kmDistance / 5.0) * 3600
            
        case .transit:
            // Average transit speed: 25 km/h (including stops)
            return (kmDistance / 25.0) * 3600
            
        default:
            return (kmDistance / 40.0) * 3600
        }
    }
    
    private static func generateDirections(waypoints: [CLLocationCoordinate2D], transportType: MKDirectionsTransportType) -> [MockDirection] {
        var directions: [MockDirection] = []
        
        // Start direction
        directions.append(MockDirection(
            instruction: getStartInstruction(transportType: transportType),
            distance: 0,
            coordinate: waypoints.first!
        ))
        
        // Generate intermediate directions
        for i in 1..<waypoints.count-1 {
            let direction = generateTurnDirection(
                from: waypoints[i-1],
                current: waypoints[i],
                to: waypoints[i+1],
                transportType: transportType
            )
            directions.append(direction)
        }
        
        // Arrival direction
        if waypoints.count > 1 {
            directions.append(MockDirection(
                instruction: "Arrive at your destination",
                distance: 0,
                coordinate: waypoints.last!
            ))
        }
        
        return directions
    }
    
    private static func getStartInstruction(transportType: MKDirectionsTransportType) -> String {
        switch transportType {
        case .automobile:
            return "Start driving"
        case .walking:
            return "Start walking"
        case .transit:
            return "Start your journey"
        default:
            return "Start your trip"
        }
    }
    
    private static func generateTurnDirection(from previous: CLLocationCoordinate2D, current: CLLocationCoordinate2D, to next: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) -> MockDirection {
        // Calculate bearing changes to determine turn direction
        let bearing1 = calculateBearing(from: previous, to: current)
        let bearing2 = calculateBearing(from: current, to: next)
        let angleDiff = normalizeAngle(bearing2 - bearing1)
        
        let distance = CLLocation(latitude: previous.latitude, longitude: previous.longitude)
            .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))
        
        let instruction: String
        
        if abs(angleDiff) < 15 {
            instruction = getContinueInstruction(transportType: transportType)
        } else if angleDiff > 15 && angleDiff < 135 {
            instruction = "Turn right"
        } else if angleDiff < -15 && angleDiff > -135 {
            instruction = "Turn left"
        } else if angleDiff >= 135 || angleDiff <= -135 {
            instruction = "Make a U-turn"
        } else {
            instruction = getContinueInstruction(transportType: transportType)
        }
        
        return MockDirection(
            instruction: instruction,
            distance: distance,
            coordinate: current
        )
    }
    
    private static func getContinueInstruction(transportType: MKDirectionsTransportType) -> String {
        switch transportType {
        case .automobile:
            return "Continue straight"
        case .walking:
            return "Keep walking straight"
        case .transit:
            return "Continue on route"
        default:
            return "Continue"
        }
    }
    
    private static func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y) * 180 / .pi
        return normalizeAngle(bearing)
    }
    
    private static func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized > 180 { normalized -= 360 }
        while normalized < -180 { normalized += 360 }
        return normalized
    }
}

// Data structures for mock route results
struct MockRouteResult {
    let polyline: MKPolyline
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let directions: [MockDirection]
    let waypoints: [CLLocationCoordinate2D]
}

struct MockDirection {
    let instruction: String
    let distance: CLLocationDistance
    let coordinate: CLLocationCoordinate2D
}

// Enhanced MKRoute extension to create custom routes
extension MKRoute {
    static func createMockRoute(from mockResult: MockRouteResult) -> MKRoute {
        // Create a custom route object that mimics MKRoute behavior
        let route = CustomMKRoute()
        route.mockPolyline = mockResult.polyline
        route.mockDistance = mockResult.distance
        route.mockExpectedTravelTime = mockResult.expectedTravelTime
        route.mockDirections = mockResult.directions
        return route
    }
}

// Custom MKRoute subclass for mock routes
class CustomMKRoute: MKRoute {
    var mockPolyline: MKPolyline!
    var mockDistance: CLLocationDistance = 0
    var mockExpectedTravelTime: TimeInterval = 0
    var mockDirections: [MockDirection] = []
    
    override var polyline: MKPolyline {
        return mockPolyline
    }
    
    override var distance: CLLocationDistance {
        return mockDistance
    }
    
    override var expectedTravelTime: TimeInterval {
        return mockExpectedTravelTime
    }
    
    override var name: String {
        return "Mock Route"
    }
    
    override var advisoryNotices: [String] {
        return ["This is a simulated route for demonstration purposes"]
    }
}
