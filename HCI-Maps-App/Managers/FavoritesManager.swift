import Foundation
import MapKit
import SwiftUI

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favorites: [FavoritePlace] = []
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "SavedFavorites"
    
    init() {
        loadFavorites()
    }
    
    func addToFavorites(_ place: MKMapItem) {
        // Check if already exists
        if favorites.contains(where: { $0.coordinate.latitude == place.placemark.coordinate.latitude &&
                                     $0.coordinate.longitude == place.placemark.coordinate.longitude }) {
            return
        }
        
        let favorite = FavoritePlace(
            id: UUID(),
            name: place.name ?? "Unknown Location",
            address: formatAddress(for: place.placemark) ?? "Unknown Address",
            coordinate: place.placemark.coordinate,
            category: formatCategory(place.pointOfInterestCategory?.rawValue ?? "Place"),
            dateAdded: Date()
        )
        
        favorites.append(favorite)
        saveFavorites()
    }
    
    func removeFromFavorites(_ place: MKMapItem) {
        favorites.removeAll { favorite in
            favorite.coordinate.latitude == place.placemark.coordinate.latitude &&
            favorite.coordinate.longitude == place.placemark.coordinate.longitude
        }
        saveFavorites()
    }
    
    func isFavorite(_ place: MKMapItem) -> Bool {
        return favorites.contains { favorite in
            favorite.coordinate.latitude == place.placemark.coordinate.latitude &&
            favorite.coordinate.longitude == place.placemark.coordinate.longitude
        }
    }
    
    func removeFavorite(by id: UUID) {
        favorites.removeAll { $0.id == id }
        saveFavorites()
    }
    
    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favorites)
            userDefaults.set(data, forKey: favoritesKey)
        } catch {
            print("Error saving favorites: \(error)")
        }
    }
    
    private func loadFavorites() {
        guard let data = userDefaults.data(forKey: favoritesKey) else {
            // Load some sample favorites for demo
            loadSampleFavorites()
            return
        }
        
        do {
            favorites = try JSONDecoder().decode([FavoritePlace].self, from: data)
        } catch {
            print("Error loading favorites: \(error)")
            loadSampleFavorites()
        }
    }
    
    private func loadSampleFavorites() {
        favorites = [
            FavoritePlace(
                id: UUID(),
                name: "Starbucks Coffee",
                address: "123 Main St, City",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                category: "Coffee Shop",
                dateAdded: Date()
            ),
            FavoritePlace(
                id: UUID(),
                name: "Central Park",
                address: "New York, NY",
                coordinate: CLLocationCoordinate2D(latitude: 40.7829, longitude: -73.9654),
                category: "Park",
                dateAdded: Date().addingTimeInterval(-86400)
            )
        ]
        saveFavorites()
    }
    
    private func formatAddress(for placemark: CLPlacemark) -> String? {
        let components = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
    
    private func formatCategory(_ category: String) -> String {
        return category.replacingOccurrences(of: "MKPOICategory", with: "")
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
}

struct FavoritePlace: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let category: String
    let dateAdded: Date
    
    var mapItem: MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = name
        return item
    }
    
    // Custom coding for CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case id, name, address, category, dateAdded
        case latitude, longitude
    }
    
    init(id: UUID, name: String, address: String, coordinate: CLLocationCoordinate2D, category: String, dateAdded: Date) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.category = category
        self.dateAdded = dateAdded
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        category = try container.decode(String.self, forKey: .category)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(category, forKey: .category)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}
