import SwiftUI
import MapKit
import CoreLocation

struct SearchResultsView: View {
    let searchText: String
    let onPlaceSelected: (MKMapItem) -> Void
    let onDismiss: () -> Void
    
    @State private var searchResults: [MKMapItem] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Search Results")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Cancel") {
                    onDismiss()
                }
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 1)
            
            // Results List
            if isLoading {
                VStack {
                    ProgressView("Searching...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    Text("Finding places and cities...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else if searchResults.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No results found")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Try searching for a different location or city")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchResults.indices, id: \.self) { index in
                            SearchResultRow(
                                place: searchResults[index],
                                onTap: {
                                    // Dismiss keyboard before selecting place
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    onPlaceSelected(searchResults[index])
                                }
                            )
                            
                            if index < searchResults.count - 1 {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
            
            Spacer(minLength: 0)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
        .onAppear {
            performSearch()
        }
        .onChange(of: searchText) { _ in
            performSearch()
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                    self.searchResults = []
                    return
                }
                
                var results = response?.mapItems ?? []
                
                // If we don't have good results and the search looks like a city name,
                // try a more specific city search
                if results.count < 3 && self.isLikelyCitySearch(self.searchText) {
                    self.performCitySearch(originalResults: results)
                } else {
                    // Sort results to prioritize cities and well-known places
                    self.searchResults = self.sortResults(results)
                }
            }
        }
    }
    
    private func performCitySearch(originalResults: [MKMapItem]) {
        let cityRequest = MKLocalSearch.Request()
        cityRequest.naturalLanguageQuery = searchText + " city"
        cityRequest.resultTypes = [.address]
        
        let citySearch = MKLocalSearch(request: cityRequest)
        citySearch.start { response, error in
            DispatchQueue.main.async {
                var allResults = originalResults
                
                if let cityResults = response?.mapItems {
                    // Add city results, avoiding duplicates
                    for cityResult in cityResults {
                        let isDuplicate = allResults.contains { existing in
                            let distance = self.distanceBetween(
                                existing.placemark.coordinate,
                                cityResult.placemark.coordinate
                            )
                            return distance < 1000 // Within 1km
                        }
                        
                        if !isDuplicate {
                            allResults.append(cityResult)
                        }
                    }
                }
                
                self.searchResults = self.sortResults(allResults)
            }
        }
    }
    
    private func sortResults(_ results: [MKMapItem]) -> [MKMapItem] {
        return results.sorted { item1, item2 in
            let isCity1 = self.isCity(item1)
            let isCity2 = self.isCity(item2)
            
            // Cities first
            if isCity1 && !isCity2 { return true }
            if !isCity1 && isCity2 { return false }
            
            // Then by name relevance to search
            let name1 = item1.name?.lowercased() ?? ""
            let name2 = item2.name?.lowercased() ?? ""
            let searchLower = self.searchText.lowercased()
            
            let score1 = name1.contains(searchLower) ? 0 : name1.count
            let score2 = name2.contains(searchLower) ? 0 : name2.count
            
            return score1 < score2
        }
    }
    
    private func isLikelyCitySearch(_ query: String) -> Bool {
        let businessTerms = ["restaurant", "coffee", "gas", "hotel", "store", "bank", "hospital"]
        let lowercaseQuery = query.lowercased()
        
        return query.count <= 20 && !businessTerms.contains { lowercaseQuery.contains($0) }
    }
    
    private func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
    
    private func isCity(_ item: MKMapItem) -> Bool {
        let placemark = item.placemark
        return placemark.locality != nil &&
               item.pointOfInterestCategory == nil &&
               placemark.thoroughfare == nil
    }
}

struct SearchResultRow: View {
    let place: MKMapItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon
                VStack {
                    Image(systemName: iconForPlace(place))
                        .font(.title2)
                        .foregroundColor(colorForPlace(place))
                        .frame(width: 30, height: 30)
                    Spacer()
                }
                
                // Place Information
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name ?? "Unknown Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let address = formatAddress(for: place.placemark) {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        if isCity(place) {
                            Text("City")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(4)
                        } else if let category = place.pointOfInterestCategory?.rawValue {
                            Text(formatCategory(category))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
    
    private func iconForPlace(_ place: MKMapItem) -> String {
        if isCity(place) {
            return "building.2.crop.circle.fill"
        }
        
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
    
    private func colorForPlace(_ place: MKMapItem) -> Color {
        if isCity(place) {
            return .purple
        } else {
            return .blue
        }
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
            placemark.administrativeArea
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
    
    private func formatCategory(_ category: String) -> String {
        return category.replacingOccurrences(of: "MKPOICategory", with: "")
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
}

#Preview {
    SearchResultsView(
        searchText: "Coffee",
        onPlaceSelected: { _ in },
        onDismiss: { }
    )
}
