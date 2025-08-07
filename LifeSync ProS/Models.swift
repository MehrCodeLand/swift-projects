import SwiftUI
import Foundation

// User model
struct User: Identifiable, Codable {
    let id = UUID()
    var name: String
    var targetWeight: Double?
    var initialWeight: Double?
    var createdAt: Date = Date()
}

// Task related models
enum TaskCategory: String, Codable {
    case work, german, exercise, coding, recovery
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .german: return .green
        case .exercise: return .red
        case .coding: return .orange
        case .recovery: return .purple
        }
    }
}

struct Task: Identifiable, Codable {
    let id = UUID()
    var title: String
    var time: String
    var duration: String
    var category: TaskCategory
    var isCompleted: Bool = false
    var date: Date = Date()
}

// Habit tracking models
struct Habit: Identifiable, Codable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var isDaily: Bool = true
    var category: String = "General"
    var createdAt: Date = Date()
}

// Weight tracking models
struct WeightEntry: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var weight: Double
}

// Water tracking models
struct WaterEntry: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var amount: Double // in liters
}

// Step tracking models
struct StepEntry: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var count: Int
}

// Sleep tracking models
struct SleepEntry: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var hours: Double
}

// Calorie tracking models
struct CalorieEntry: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var calories: Int
    var description: String
}

// Study tracking models
struct StudySession: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var duration: Int
    var type: StudyType
}

enum StudyType: String, Codable {
    case grammar, vocabulary, speaking, practice
}

struct StudyTask: Identifiable, Codable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
}

// Statistics models
struct TimeAllocation: Identifiable {
    let id = UUID()
    let category: String
    let hours: Double
    let color: Color
}

struct EnergyLevel: Identifiable {
    let id = UUID()
    let hour: Int
    let level: Int
}
