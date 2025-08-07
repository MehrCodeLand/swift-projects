import SwiftUI

struct AppTheme {
    // Claude AI-like dark mode colors
    static let backgroundColor = Color(red: 0.08, green: 0.08, blue: 0.1)
    static let foregroundColor = Color.white
    static let accentColor = Color(red: 0.4, green: 0.5, blue: 1.0)
    static let secondaryBackgroundColor = Color(red: 0.15, green: 0.15, blue: 0.2)
    
    // Fonts
    static let defaultFont = Font.system(size: 16)
    static let titleFont = Font.system(size: 24, weight: .bold)
    
    // Available fonts for user selection
    static let availableFonts = [
        "System", "SF Pro", "New York", "Helvetica Neue", "Times New Roman", "Arial", "Courier"
    ]
}

// Font selection view
struct FontSelectionView: View {
    @AppStorage("selectedFont") var selectedFont: String = "System"
    
    var body: some View {
        Picker("Font", selection: $selectedFont) {
            ForEach(AppTheme.availableFonts, id: \.self) { font in
                Text(font)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}
