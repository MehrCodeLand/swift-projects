import Foundation
import SwiftUI

class NotesManager: ObservableObject {
    @Published var notes: [Note] = []
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    init() {
        loadNotes()
    }
    
    func saveNote(_ note: Note) {
        // Save logic using JSON encoding
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        } else {
            notes.append(note)
        }
        
        saveNotes()
    }
    
    private func saveNotes() {
        // Save all notes to JSON files
        for note in notes {
            let fileName = getFileName(for: note)
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(note)
                try data.write(to: fileURL)
            } catch {
                print("Error saving note: \(error)")
            }
        }
    }
    
    private func loadNotes() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }
            
            for fileURL in jsonFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    let note = try decoder.decode(Note.self, from: data)
                    notes.append(note)
                } catch {
                    print("Error decoding note: \(error)")
                }
            }
        } catch {
            print("Error loading notes: \(error)")
        }
    }
    
    private func getFileName(for note: Note) -> String {
        switch note.type {
        case .now:
            return "Now\(note.index).json"
        case .theDay:
            return "\(note.title).json"
        }
    }
}
