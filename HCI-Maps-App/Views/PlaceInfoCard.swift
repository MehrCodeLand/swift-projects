import SwiftUI
import MapKit

struct PlaceInfoCard: View {
    let place: MKMapItem
    let route: MKRoute?
    let isFavorite: Bool
    let onDismiss: () -> Void
    let onGetDirections: () -> Void
    let onFavoriteToggle: () -> Void
    
    @State private var showingDirections = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.name ?? "Unknown Location")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let address = formatAddress(for: place.placemark) {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Favorite Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                onFavoriteToggle()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isFavorite ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                    .scaleEffect(isFavorite ? 1.05 : 1.0)
                                
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(isFavorite ? .red : .gray)
                                    .font(.system(size: 20, weight: .medium))
                                    .scaleEffect(isFavorite ? 1.2 : 1.0)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorite)
                        
                        // Close Button
                        Button(action: onDismiss) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "xmark")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Category and Rating
                HStack {
                    if let category = place.pointOfInterestCategory?.rawValue {
                        CategoryTag(
                            icon: iconForCategory(category),
                            text: formatCategory(category),
                            color: .blue
                        )
                    } else if isCity(place) {
                        CategoryTag(
                            icon: "building.2",
                            text: "City",
                            color: .purple
                        )
                    }
                    
                    Spacer()
                    
                    // Mock rating for HCI demo (only for POI, not cities)
                    if !isCity(place) {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < 4 ? "star.fill" : "star")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                            Text("4.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Directions Button
                        if !isCity(place) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingDirections = true
                                }
                                onGetDirections()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Directions")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                .scaleEffect(showingDirections ? 0.95 : 1.0)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Call Button (Mock)
                            Button(action: {
                                // Mock call functionality with haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                print("Calling place...")
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Call")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // For cities, show explore button
                            Button(action: {
                                print("Exploring city...")
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.magnifyingglass")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Explore City")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Additional Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Information")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        if !isCity(place) {
                            // Mock business hours for places
                            InfoRow(
                                icon: "clock",
                                iconColor: .blue,
                                title: "Open • Closes 10:00 PM",
                                titleColor: .primary
                            )
                            
                            // Mock website for places
                            InfoRow(
                                icon: "globe",
                                iconColor: .blue,
                                title: "Visit Website",
                                titleColor: .blue
                            )
                        } else {
                            // City information
                            InfoRow(
                                icon: "building.2",
                                iconColor: .purple,
                                title: "Population: ~2.5M",
                                titleColor: .primary
                            )
                            
                            InfoRow(
                                icon: "map",
                                iconColor: .purple,
                                title: "View city attractions",
                                titleColor: .purple
                            )
                        }
                        
                        // Distance from user (for both cities and places)
                        if let coordinate = place.placemark.location?.coordinate {
                            InfoRow(
                                icon: "location",
                                iconColor: .blue,
                                title: distanceText(to: coordinate),
                                titleColor: .primary
                            )
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func isCity(_ place: MKMapItem) -> Bool {
        let placemark = place.placemark
        return placemark.locality != nil &&
               place.pointOfInterestCategory == nil &&
               placemark.thoroughfare == nil
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
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case let cat where cat.contains("restaurant") || cat.contains("food"):
            return "fork.knife"
        case let cat where cat.contains("gas"):
            return "fuelpump"
        case let cat where cat.contains("hospital"):
            return "cross"
        case let cat where cat.contains("school") || cat.contains("university"):
            return "graduationcap"
        case let cat where cat.contains("store") || cat.contains("shop"):
            return "bag"
        case let cat where cat.contains("bank"):
            return "dollarsign"
        case let cat where cat.contains("hotel"):
            return "bed.double"
        default:
            return "mappin"
        }
    }
    
    private func formatCategory(_ category: String) -> String {
        return category.replacingOccurrences(of: "MKPOICategory", with: "")
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
    
    private func distanceText(to coordinate: CLLocationCoordinate2D) -> String {
        // Mock distance calculation for demo
        let distances = ["0.2 km away", "0.5 km away", "1.1 km away", "2.3 km away", "15 km away", "45 km away"]
        return distances.randomElement() ?? "Nearby"
    }
}

// Custom UI Components
struct CategoryTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let titleColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(titleColor)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    PlaceInfoCard(
        place: MKMapItem(),
        route: nil,
        isFavorite: false,
        onDismiss: { },
        onGetDirections: { },
        onFavoriteToggle: { }
    )
}
