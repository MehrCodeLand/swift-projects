import Foundation

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: NSAttributedString.AttributedStringJSON
    var creationDate: Date
    var type: NoteType
    var index: Int
    
    enum NoteType: String, Codable {a
        case now
        case theDay
    }
}


// Extension to allow NSAttributedString to be saved to JSON
extension NSAttributedString {
    struct AttributedStringJSON: Codable {
        let string: String
        let attributes: [Int: [String: Any]]
        
        // Implementation details for encoding/decoding the NSAttributedString
    }
}
