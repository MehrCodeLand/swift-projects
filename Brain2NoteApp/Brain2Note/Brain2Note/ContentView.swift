import SwiftUI

struct ContentView: View {
    @StateObject private var notesManager = NotesManager()
    @State private var selectedNoteType: Note.NoteType = .now
    @State private var selectedNote: Note?
    @State private var newNoteTitle = ""
    @State private var textEditor = NSTextView()
    
    var body: some View {
        NavigationView {
            // Sidebar
            VStack {
                List {
                    Section(header: Text("Note Type")) {
                        Button("The Day") {
                            selectedNoteType = .theDay
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(8)
                        .background(selectedNoteType == .theDay ? Color.gray.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                        
                        Button("Now") {
                            selectedNoteType = .now
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(8)
                        .background(selectedNoteType == .now ? Color.gray.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                    }
                    
                    Section(header: Text("Notes")) {
                        ForEach(notesManager.notes.filter { $0.type == selectedNoteType }) { note in
                            Text(note.title)
                                .onTapGesture {
                                    selectedNote = note
                                }
                        }
                    }
                }
                
                Button("New Note") {
                    createNewNote()
                }
                .padding()
            }
            .frame(minWidth: 200)
            
            // Note Editor
            VStack {
                if let note = selectedNote {
                    TextField("Title", text: Binding(
                        get: { note.title },
                        set: { newTitle in
                            var updatedNote = note
                            updatedNote.title = newTitle
                            notesManager.saveNote(updatedNote)
                            selectedNote = updatedNote
                        }
                    ))
                    .font(.title)
                    .padding()
                    
                    NoteEditorView(note: note, onSave: { updatedNote in
                        notesManager.saveNote(updatedNote)
                        selectedNote = updatedNote
                    })
                } else {
                    Text("Select a note or create a new one")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    private func createNewNote() {
        let newNote: Note
        
        if selectedNoteType == .now {
            let nowNotes = notesManager.notes.filter { $0.type == .now }
            let newIndex = nowNotes.count + 1
            
            newNote = Note(
                title: "Now \(newIndex)",
                content: NSAttributedString().attributedStringJSON,
                creationDate: Date(),
                type: .now,
                index: newIndex
            )
        } else {
            newNote = Note(
                title: "New Day Note",
                content: NSAttributedString().attributedStringJSON,
                creationDate: Date(),
                type: .theDay,
                index: 0
            )
        }
        
        notesManager.saveNote(newNote)
        selectedNote = newNote
    }
}
