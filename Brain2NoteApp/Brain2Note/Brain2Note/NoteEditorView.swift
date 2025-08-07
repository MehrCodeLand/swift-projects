import SwiftUI

struct NoteEditorView: NSViewRepresentable {
    var note: Note
    var onSave: (Note) -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .white
        textView.backgroundColor = NSColor(Color("BackgroundColor"))
        textView.delegate = context.coordinator
        
        // Load the text content from the note
        if let attributedString = try? NSAttributedString(from: note.content) {
            textView.textStorage?.setAttributedString(attributedString)
        }
        
        // Set up scroll view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Update view if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NoteEditorView
        
        init(_ parent: NoteEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let attributedString = textView.attributedString()
            
            var updatedNote = parent.note
            updatedNote.content = attributedString.attributedStringJSON
            parent.onSave(updatedNote)
        }
    }
}

// Extension to handle formatting toolbar
struct TextFormattingCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button("Bold") {
                NSApp.sendAction(#selector(NSTextView.toggleBoldface(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("b", modifiers: .command)
            
            Button("Italic") {
                NSApp.sendAction(#selector(NSTextView.toggleItalics(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("i", modifiers: .command)
            
            Button("Underline") {
                NSApp.sendAction(#selector(NSTextView.toggleUnderline(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("u", modifiers: .command)
            
            // Add more formatting options here
        }
    }
}
