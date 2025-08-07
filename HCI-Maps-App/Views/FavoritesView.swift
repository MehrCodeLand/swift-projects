import SwiftUI
import MapKit

struct FavoritesView: View {
    @ObservedObject var favoritesManager: FavoritesManager
    let onPlaceSelected: (MKMapItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if favoritesManager.favorites.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Favorite Places")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Places you mark as favorites will appear here for quick access")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Explore Places") {
                            dismiss()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Favorites List
                    List {
                        ForEach(favoritesManager.favorites) { favorite in
                            FavoriteRow(
                                favorite: favorite,
                                onTap: {
                                    onPlaceSelected(favorite.mapItem)
                                    dismiss()
                                },
                                onDelete: {
                                    favoritesManager.removeFavorite(by: favorite.id)
                                }
                            )
                        }
                        .onDelete(perform: deleteFavorites)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !favoritesManager.favorites.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
        }
    }
    
    private func deleteFavorites(offsets: IndexSet) {
        for index in offsets {
            let favorite = favoritesManager.favorites[index]
            favoritesManager.removeFavorite(by: favorite.id)
        }
    }
}

struct FavoriteRow: View {
    let favorite: FavoritePlace
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon
                Image(systemName: iconForCategory(favorite.category))
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 40, height: 40)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
                
                // Place Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(favorite.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(favorite.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(favorite.category)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text(formatDate(favorite.dateAdded))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case let cat where cat.contains("coffee") || cat.contains("restaurant"):
            return "cup.and.saucer.fill"
        case let cat where cat.contains("park"):
            return "tree.fill"
        case let cat where cat.contains("store") || cat.contains("shop"):
            return "bag.fill"
        case let cat where cat.contains("gas"):
            return "fuelpump.fill"
        case let cat where cat.contains("hospital"):
            return "cross.fill"
        case let cat where cat.contains("school"):
            return "graduationcap.fill"
        case let cat where cat.contains("bank"):
            return "dollarsign.circle.fill"
        case let cat where cat.contains("hotel"):
            return "bed.double.fill"
        case let cat where cat.contains("city"):
            return "building.2.crop.circle.fill"
        default:
            return "mappin.circle.fill"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    FavoritesView(favoritesManager: FavoritesManager.shared) { _ in }
}
