// Updated DataManager class with user support and real data
import SwiftUI
import Combine
import Foundation

class DataManager: ObservableObject {
    // User information
    @Published var currentUser: User?
    @Published var hasCompletedOnboarding: Bool = false
    
    // Weight & health tracking
    @Published var currentWeight: Double = 0.0
    @Published var targetWeight: Double = 0.0
    @Published var weightHistory: [WeightEntry] = []
    @Published var waterIntake: [WaterEntry] = []
    @Published var stepEntries: [StepEntry] = []
    @Published var sleepEntries: [SleepEntry] = []
    @Published var calorieEntries: [CalorieEntry] = []
    
    // Tasks and habits
    @Published var tasks: [Task] = []
    @Published var habits: [Habit] = []
    
    // Study tracking
    @Published var germanStudyStreak: Int = 0
    @Published var codingStreak: Int = 0
    @Published var germanStudyProgress: [StudySession] = []
    
    // User defaults keys
    private let userKey = "userData"
    private let onboardingKey = "hasCompletedOnboarding"
    private let weightHistoryKey = "weightHistory"
    private let waterIntakeKey = "waterIntake"
    private let stepEntriesKey = "stepEntries"
    private let sleepEntriesKey = "sleepEntries"
    private let calorieEntriesKey = "calorieEntries"
    private let tasksKey = "tasks"
    private let habitsKey = "habits"
    private let germanStudyKey = "germanStudy"
    
    init() {
        loadData()
    }
    
    // MARK: - User Management
    
    func setUser(_ user: User) {
        self.currentUser = user
        self.hasCompletedOnboarding = true
        
        // Set initial values based on user data
        if let targetWeight = user.targetWeight {
            self.targetWeight = targetWeight
        }
        
        if let initialWeight = user.initialWeight {
            self.currentWeight = initialWeight
        }
        
        saveData()
    }
    
    // MARK: - Weight Tracking
    
    func addWeightEntry(weight: Double) {
        let entry = WeightEntry(date: Date(), weight: weight)
        weightHistory.append(entry)
        currentWeight = weight
        saveData()
    }
    
    // MARK: - Water Tracking
    
    func addWaterIntake(amount: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let index = waterIntake.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            waterIntake[index].amount += amount
        } else {
            waterIntake.append(WaterEntry(date: today, amount: amount))
        }
        
        saveData()
    }
    
    // MARK: - Step Tracking
    
    func addSteps(count: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let index = stepEntries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            stepEntries[index].count += count
        } else {
            stepEntries.append(StepEntry(date: today, count: count))
        }
        
        saveData()
    }
    
    // MARK: - Sleep Tracking
    
    func addSleepEntry(hours: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        sleepEntries.append(SleepEntry(date: today, hours: hours))
        saveData()
    }
    
    // MARK: - Calorie Tracking
    
    func addCalorieEntry(calories: Int, description: String) {
        let entry = CalorieEntry(date: Date(), calories: calories, description: description)
        calorieEntries.append(entry)
        saveData()
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveData()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveData()
        }
    }
    
    // MARK: - Habit Management
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveData()
    }
    
    func toggleHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isCompleted.toggle()
            saveData()
        }
    }
    
    // MARK: - Study Tracking
    
    func addStudySession(duration: Int, type: StudyType) {
        let session = StudySession(date: Date(), duration: duration, type: type)
        germanStudyProgress.append(session)
        updateStudyStreak()
        saveData()
    }
    
    private func updateStudyStreak() {
        // Logic to calculate streak based on consecutive days with study sessions
        let calendar = Calendar.current
        let sortedSessions = germanStudyProgress.sorted { $0.date > $1.date }
        
        guard !sortedSessions.isEmpty else {
            germanStudyStreak = 0
            return
        }
        
        var currentStreak = 1
        var checkDate = calendar.startOfDay(for: sortedSessions[0].date)
        
        for i in 1..<sortedSessions.count {
            let previousDate = calendar.startOfDay(for: sortedSessions[i].date)
            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: checkDate).day ?? 0
            
            if daysBetween == 1 {
                currentStreak += 1
                checkDate = previousDate
            } else if daysBetween > 1 {
                break
            }
        }
        
        germanStudyStreak = currentStreak
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        let defaults = UserDefaults.standard
        
        // Load user and onboarding status
        if let userData = defaults.data(forKey: userKey),
           let decodedUser = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = decodedUser
        }
        
        hasCompletedOnboarding = defaults.bool(forKey: onboardingKey)
        
        // Load weight history
        if let weightData = defaults.data(forKey: weightHistoryKey),
           let decodedWeightHistory = try? JSONDecoder().decode([WeightEntry].self, from: weightData) {
            weightHistory = decodedWeightHistory
            if let lastWeight = weightHistory.last {
                currentWeight = lastWeight.weight
            }
        }
        
        // Load water intake
        if let waterData = defaults.data(forKey: waterIntakeKey),
           let decodedWaterIntake = try? JSONDecoder().decode([WaterEntry].self, from: waterData) {
            waterIntake = decodedWaterIntake
        }
        
        // Load step entries
        if let stepData = defaults.data(forKey: stepEntriesKey),
           let decodedStepEntries = try? JSONDecoder().decode([StepEntry].self, from: stepData) {
            stepEntries = decodedStepEntries
        }
        
        // Load sleep entries
        if let sleepData = defaults.data(forKey: sleepEntriesKey),
           let decodedSleepEntries = try? JSONDecoder().decode([SleepEntry].self, from: sleepData) {
            sleepEntries = decodedSleepEntries
        }
        
        // Load calorie entries
        if let calorieData = defaults.data(forKey: calorieEntriesKey),
           let decodedCalorieEntries = try? JSONDecoder().decode([CalorieEntry].self, from: calorieData) {
            calorieEntries = decodedCalorieEntries
        }
        
        // Load tasks
        if let tasksData = defaults.data(forKey: tasksKey),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: tasksData) {
            tasks = decodedTasks
        }
        
        // Load habits
        if let habitsData = defaults.data(forKey: habitsKey),
           let decodedHabits = try? JSONDecoder().decode([Habit].self, from: habitsData) {
            habits = decodedHabits
        }
        
        // Load study data
        if let studyData = defaults.data(forKey: germanStudyKey),
           let decodedStudyProgress = try? JSONDecoder().decode([StudySession].self, from: studyData) {
            germanStudyProgress = decodedStudyProgress
            updateStudyStreak()
        }
        
        // Set target weight from user if available
        if let user = currentUser, let targetWeight = user.targetWeight {
            self.targetWeight = targetWeight
        }
    }
    
    func saveData() {
        let defaults = UserDefaults.standard
        
        // Save user and onboarding status
        if let user = currentUser, let encodedUser = try? JSONEncoder().encode(user) {
            defaults.set(encodedUser, forKey: userKey)
        }
        
        defaults.set(hasCompletedOnboarding, forKey: onboardingKey)
        
        // Save weight history
        if let encodedWeightHistory = try? JSONEncoder().encode(weightHistory) {
            defaults.set(encodedWeightHistory, forKey: weightHistoryKey)
        }
        
        // Save water intake
        if let encodedWaterIntake = try? JSONEncoder().encode(waterIntake) {
            defaults.set(encodedWaterIntake, forKey: waterIntakeKey)
        }
        
        // Save step entries
        if let encodedStepEntries = try? JSONEncoder().encode(stepEntries) {
            defaults.set(encodedStepEntries, forKey: stepEntriesKey)
        }
        
        // Save sleep entries
        if let encodedSleepEntries = try? JSONEncoder().encode(sleepEntries) {
            defaults.set(encodedSleepEntries, forKey: sleepEntriesKey)
        }
        
        // Save calorie entries
        if let encodedCalorieEntries = try? JSONEncoder().encode(calorieEntries) {
            defaults.set(encodedCalorieEntries, forKey: calorieEntriesKey)
        }
        
        // Save tasks
        if let encodedTasks = try? JSONEncoder().encode(tasks) {
            defaults.set(encodedTasks, forKey: tasksKey)
        }
        
        // Save habits
        if let encodedHabits = try? JSONEncoder().encode(habits) {
            defaults.set(encodedHabits, forKey: habitsKey)
        }
        
        // Save study data
        if let encodedStudyProgress = try? JSONEncoder().encode(germanStudyProgress) {
            defaults.set(encodedStudyProgress, forKey: germanStudyKey)
        }
    }
    
    // MARK: - Helper Methods
    
    func getTodayWaterIntake() -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        return waterIntake.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.amount ?? 0.0
    }
    
    func getTodaySteps() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return stepEntries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.count ?? 0
    }
    
    func getTodayCalories() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return calorieEntries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.calories }
    }
    
    func getWeeklyCalories() -> [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).map { day in
            guard let date = calendar.date(byAdding: .day, value: -day, to: today) else { return 0 }
            
            return calorieEntries
                .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.calories }
        }.reversed()
    }
    
    func getWeeklyAverageWaterIntake() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var total: Double = 0
        var count = 0
        
        for day in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: today) else { continue }
            
            if let entry = waterIntake.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                total += entry.amount
                count += 1
            }
        }
        
        return count > 0 ? total / Double(count) : 0
    }
    
    func resetDailyProgress() {
        // Reset daily progress for habits
        for (index, habit) in habits.enumerated() {
            if habit.isDaily {
                habits[index].isCompleted = false
            }
        }
        
        saveData()
    }
}
