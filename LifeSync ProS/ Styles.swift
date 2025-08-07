import SwiftUI

extension Color {
    static let customBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let customGreen = Color(red: 0.0, green: 0.8, blue: 0.0)
    static let customRed = Color(red: 1.0, green: 0.231, blue: 0.188)
    static let customOrange = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let customPurple = Color(red: 0.686, green: 0.322, blue: 0.87)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .shadow(radius: 1, x: 0, y: 1)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}
