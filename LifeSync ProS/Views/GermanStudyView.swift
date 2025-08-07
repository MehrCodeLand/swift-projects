import SwiftUI

struct GermanStudyView: View {
    @ObservedObject var userDataManager: UserDataManager
    @State private var showingExamDatePicker = false
    @State private var showingAddStudySession = false
    @State private var examDate: Date
    @State private var todoItems = [
        StudyTask(title: "Grammar Ch.12", isCompleted: false),
        StudyTask(title: "50 new words", isCompleted: false),
        StudyTask(title: "Speaking practice", isCompleted: false)
    ]
    
    init(userDataManager: UserDataManager) {
        self.userDataManager = userDataManager
        _examDate = State(initialValue: userDataManager.b2ExamDate)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Exam Countdown
                    ExamCountdownCard(userDataManager: userDataManager, showingExamDatePicker: $showingExamDatePicker)
                    
                    // Weekly Progress
                    WeeklyStudyProgress(userDataManager: userDataManager)
                    
                    // Today's Focus
                    TodayStudyFocus(userDataManager: userDataManager, todoItems: $todoItems)
                    
                    // Study Stats
                    StudyStatistics(userDataManager: userDataManager)
                }
                .padding()
            }
            .navigationTitle("German Study")
            .navigationBarItems(trailing: addButton)
            .sheet(isPresented: $showingExamDatePicker) {
                ExamDatePickerView(userDataManager: userDataManager, examDate: $examDate)
            }
            .sheet(isPresented: $showingAddStudySession) {
                AddStudySessionView(userDataManager: userDataManager)
            }
        }
    }
    
    private var addButton: some View {
        Button(action: { showingAddStudySession = true }) {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Exam Countdown Card
struct ExamCountdownCard: View {
    @ObservedObject var userDataManager: UserDataManager
    @Binding var showingExamDatePicker: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Text("B2 Exam in:")
                .font(.headline)
                .foregroundColor(.gray)
            
            Button(action: { showingExamDatePicker = true }) {
                Text("\(daysUntilExam()) days")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func daysUntilExam() -> Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: userDataManager.b2ExamDate).day ?? 0
        return max(0, days)
    }
}

// MARK: - Weekly Study Progress
struct WeeklyStudyProgress: View {
    @ObservedObject var userDataManager: UserDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.gray)
            
            // Get weekly data from UserDataManager
            let weeklyData = getWeeklyStudyData()
            
            VStack(spacing: 10) {
                StudyProgressItem(title: "Study", current: weeklyData.totalHours, target: 14.0, isCompleted: weeklyData.totalHours >= 14.0)
                StudyProgressItem(title: "Speaking", current: weeklyData.speakingHours, target: 3, isCompleted: weeklyData.speakingHours >= 3)
                StudyProgressItem(title: "Practice", current: weeklyData.practiceHours, target: 2, isCompleted: weeklyData.practiceHours >= 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private struct WeeklyStudyData {
        var totalHours: Double = 0
        var speakingHours: Double = 0
        var practiceHours: Double = 0
    }
    
    private func getWeeklyStudyData() -> WeeklyStudyData {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        var data = WeeklyStudyData()
        
        for session in userDataManager.germanStudySessions {
            if session.date >= startOfWeek && session.date <= today {
                let hours = Double(session.duration) / 60.0
                data.totalHours += hours
                
                switch session.type {
                case .speaking:
                    data.speakingHours += hours
                case .practice:
                    data.practiceHours += hours
                default:
                    break
                }
            }
        }
        
        return data
    }
}

// MARK: - Today Study Focus
struct TodayStudyFocus: View {
    @ObservedObject var userDataManager: UserDataManager
    @Binding var todoItems: [StudyTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Focus")
                .font(.headline)
                .foregroundColor(.gray)
            
            if userDataManager.germanStudySessions.isEmpty && todoItems.isEmpty {
                Text("Add study sessions to track your progress")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(0..<todoItems.count, id: \.self) { index in
                    Button(action: {
                        todoItems[index].isCompleted.toggle()
                        // Save updated todo items to UserDataManager if needed
                        userDataManager.saveGermanTodoItems(todoItems)
                    }) {
                        HStack {
                            Image(systemName: todoItems[index].isCompleted ? "checkmark.square.fill" : "square")
                                .foregroundColor(todoItems[index].isCompleted ? .green : .gray)
                            Text(todoItems[index].title)
                                .strikethrough(todoItems[index].isCompleted)
                                .foregroundColor(todoItems[index].isCompleted ? .gray : .primary)
                            Spacer()
                        }
                    }
                }
                
                // If you have German tasks in userDataManager, display them too
                if let germanTasks = getTodayGermanTasks() {
                    ForEach(germanTasks) { task in
                        Button(action: {
                            userDataManager.toggleTaskCompletion(task)
                        }) {
                            HStack {
                                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                                    .foregroundColor(task.isCompleted ? .green : .gray)
                                Text(task.title)
                                    .strikethrough(task.isCompleted)
                                    .foregroundColor(task.isCompleted ? .gray : .primary)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getTodayGermanTasks() -> [Task]? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let germanTasks = userDataManager.tasks.filter { task in
            task.category == .german && calendar.isDate(task.date, inSameDayAs: today)
        }
        
        return germanTasks.isEmpty ? nil : germanTasks
    }
}

// MARK: - Study Statistics
struct StudyStatistics: View {
    @ObservedObject var userDataManager: UserDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Study Statistics")
                .font(.headline)
                .foregroundColor(.gray)
            
            HStack(spacing: 20) {
                StatCard(title: "Current Streak", value: "\(userDataManager.germanStudyStreak)", unit: "days", color: .orange)
                StatCard(title: "Total Hours", value: "\(getTotalStudyHours())", unit: "hrs", color: .blue)
                StatCard(title: "Vocab Progress", value: "\(estimateVocabProgress())", unit: "words", color: .green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getTotalStudyHours() -> String {
        let totalMinutes = userDataManager.germanStudySessions.reduce(0) { $0 + $1.duration }
        let hours = Double(totalMinutes) / 60.0
        return String(format: "%.1f", hours)
    }
    
    private func estimateVocabProgress() -> String {
        // Estimate vocabulary based on study hours (just a sample calculation)
        let totalMinutes = userDataManager.germanStudySessions.reduce(0) { $0 + $1.duration }
        let vocabularyLearned = Int(Double(totalMinutes) / 60.0 * 10) // Assume 10 words per hour on average
        
        // If no data, return 0
        if totalMinutes == 0 {
            return "0"
        }
        
        return "\(vocabularyLearned)"
    }
}

// MARK: - Study Progress Item
struct StudyProgressItem: View {
    let title: String
    let current: Double
    let target: Double
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text("\(current, specifier: "%.1f")/\(target, specifier: "%.1f")h")
                .font(.subheadline)
                .foregroundColor(.gray)
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Exam Date Picker View
struct ExamDatePickerView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Binding var examDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("B2 Exam Date")) {
                    DatePicker("Select Date", selection: $examDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                Section {
                    Button("Save") {
                        userDataManager.updateExamDate(examDate)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Set Exam Date")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Add Study Session View
struct AddStudySessionView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var duration = 60
    @State private var selectedType: StudyType = .grammar
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Study Session")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Picker("Type", selection: $selectedType) {
                        Text("Grammar").tag(StudyType.grammar)
                        Text("Vocabulary").tag(StudyType.vocabulary)
                        Text("Speaking").tag(StudyType.speaking)
                        Text("Practice").tag(StudyType.practice)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Stepper(value: $duration, in: 15...180, step: 15) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(duration) min (\(duration/60)h \(duration%60)min)")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section {
                    Button("Add Study Session") {
                        userDataManager.addStudySession(duration: duration, type: selectedType, date: date)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("New Study Session")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
