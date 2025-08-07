import SwiftUI

@main
struct Brain2NoteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .preferredColorScheme(.dark)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            TextFormattingCommands()
            SidebarCommands()
        }
    }
}
