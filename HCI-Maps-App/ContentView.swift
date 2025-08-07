import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @State private var selectedPlace: MKMapItem?
    @State private var route: MKRoute?
    @State private var showingRouteOptions = false
    @State private var transportType: MKDirectionsTransportType = .automobile
    @State private var showingFavorites = false
    @State private var showingDirectionAlert = false
    @State private var showingServiceUnavailable = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var shouldFocusOnLocation = false
    @State private var isTrackingUser = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ZStack {
            // Main Map View
            MapView(
                locationManager: locationManager,
                selectedPlace: $selectedPlace,
                route: $route,
                transportType: transportType,
                mapRegion: $mapRegion,
                shouldFocusOnLocation: $shouldFocusOnLocation,
                isTrackingUser: $isTrackingUser
            )
            .ignoresSafeArea()
            .onTapGesture {
                // Dismiss keyboard when tapping on map
                isSearchFocused = false
            }
            
            // Top Search Bar
            VStack {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search for places or cities...", text: $searchText)
                            .focused($isSearchFocused)
                            .onSubmit {
                                searchForPlaces()
                                isSearchFocused = false
                            }
                        
                        if !searchText.isEmpty {
                            Button("Clear") {
                                searchText = ""
                                selectedPlace = nil
                                route = nil
                                showingSearchResults = false
                                isSearchFocused = false
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    
                    // Favorites Button
                    Button(action: {
                        showingFavorites.toggle()
                        isSearchFocused = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                            
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 22, weight: .medium))
                                .scaleEffect(showingFavorites ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingFavorites)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Bottom Controls
                HStack {
                    // My Location Button
                    Button(action: {
                        focusOnCurrentLocation()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                            
                            Image(systemName: isTrackingUser ? "location.fill" : "location")
                                .foregroundColor(isTrackingUser ? .white : .blue)
                                .font(.system(size: 20, weight: .medium))
                                .background(
                                    Circle()
                                        .fill(isTrackingUser ? Color.blue : Color.clear)
                                        .frame(width: 40, height: 40)
                                )
                                .scaleEffect(isTrackingUser ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTrackingUser)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            
            // Search Results
            if showingSearchResults && !searchText.isEmpty {
                SearchResultsView(
                    searchText: searchText,
                    onPlaceSelected: { place in
                        selectedPlace = place
                        showingSearchResults = false
                        isSearchFocused = false
                        
                        // Focus on the selected place/city
                        focusOnPlace(place)
                    },
                    onDismiss: {
                        showingSearchResults = false
                        isSearchFocused = false
                    }
                )
                .transition(.move(edge: .top))
            }
            
            // Selected Place Info Card
            if let place = selectedPlace {
                VStack {
                    Spacer()
                    PlaceInfoCard(
                        place: place,
                        route: route,
                        isFavorite: favoritesManager.isFavorite(place),
                        onDismiss: {
                            selectedPlace = nil
                            route = nil
                        },
                        onGetDirections: {
                            // Show confirmation alert
                            showingDirectionAlert = true
                        },
                        onFavoriteToggle: {
                            toggleFavorite(place)
                        }
                    )
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesView(
                favoritesManager: favoritesManager
            ) { place in
                selectedPlace = place
                showingFavorites = false
                focusOnPlace(place)
            }
        }
        .alert("Navigation", isPresented: $showingDirectionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes") {
                showingServiceUnavailable = true
            }
        } message: {
            Text("Do you want directions to this location?")
        }
        .alert("Service Unavailable", isPresented: $showingServiceUnavailable) {
            Button("OK") {
                // Clear route if any
                route = nil
            }
        } message: {
            Text("Navigation service is currently not available. Please try again later.")
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation, shouldFocusOnLocation {
                updateMapRegion(to: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                shouldFocusOnLocation = false
                isTrackingUser = true
                
                // Auto-disable tracking after 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    isTrackingUser = false
                }
            }
        }
        .onChange(of: isSearchFocused) { focused in
            if focused {
                showingSearchResults = true
            }
        }
    }
    
    private func searchForPlaces() {
        guard !searchText.isEmpty else { return }
        showingSearchResults = true
    }
    
    private func focusOnCurrentLocation() {
        // Dismiss keyboard first
        isSearchFocused = false
        
        // Disable tracking from any other location
        isTrackingUser = false
        
        // Request fresh location
        locationManager.requestLocation()
        shouldFocusOnLocation = true
        
        // Clear any selected place when focusing on current location
        selectedPlace = nil
        route = nil
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func focusOnPlace(_ place: MKMapItem) {
        // Disable user tracking when focusing on a place
        isTrackingUser = false
        
        let coordinate = place.placemark.coordinate
        
        // Determine zoom level based on place type
        let span: MKCoordinateSpan
        if place.placemark.locality != nil && place.pointOfInterestCategory == nil {
            // It's a city - zoom out more
            span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        } else {
            // It's a specific place - zoom in more
            span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        }
        
        updateMapRegion(to: coordinate, span: span)
    }
    
    private func updateMapRegion(to coordinate: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion = MKCoordinateRegion(center: coordinate, span: span)
        }
    }
    
    private func toggleFavorite(_ place: MKMapItem) {
        if favoritesManager.isFavorite(place) {
            favoritesManager.removeFromFavorites(place)
        } else {
            favoritesManager.addToFavorites(place)
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    ContentView()
}
