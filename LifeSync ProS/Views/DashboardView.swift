import SwiftUI
import Charts

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var userDataManager: UserDataManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome message
                    welcomeMessage
                    
                    // Stats summary
                    statsSummary
                    
                    // Today's Focus Card
                    todaysFocusCard
                    
                    // Next Task Card
                    nextTaskCard
                    
                    // Quick Actions
                    quickActionsView
                    
                    // Progress Overview
                    progressOverview
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
    
    // Welcome message with user name
    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let user = userDataManager.currentUser {
                Text("Hello, \(user.name)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(getDayGreeting())
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 5)
    }
    
    // Stats summary
    private var statsSummary: some View {
        HStack(spacing: 15) {
            // Weight card
            VStack(spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(userDataManager.currentWeight, specifier: "%.1f")")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("kg")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("Weight")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Water card
            VStack(spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(userDataManager.getTodayWaterIntake(), specifier: "%.1f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("L")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("Water")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Steps card
            VStack(spacing: 5) {
                Text("\(userDataManager.getTodaySteps())")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Steps")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Calories card
            VStack(spacing: 5) {
                Text("\(userDataManager.getTodayCalories())")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("Calories")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // Today's focus card
    private var todaysFocusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Focus")
                .font(.headline)
                .foregroundColor(.gray)
            
            // Display tasks for today
            if let todayTasks = getTodayTasks(), !todayTasks.isEmpty {
                ForEach(todayTasks.prefix(3)) { task in
                    HStack {
                        Label(task.title, systemImage: getIconForCategory(task.category))
                            .foregroundColor(task.category.color)
                        Spacer()
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                    }
                }
            } else {
                Text("No tasks scheduled for today")
                    .foregroundColor(.gray)
                    .italic()
            }
            
            // Weight progress if available
            if let weightProgress = getWeightProgressText() {
                HStack {
                    Label("Weight: \(weightProgress)", systemImage: "scalemass")
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Next task card
    private var nextTaskCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next Task")
                .font(.headline)
                .foregroundColor(.gray)
            
            if let nextTask = getNextTask() {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(nextTask.time) \(nextTask.title)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(nextTask.duration)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        // Toggle completion
                        userDataManager.toggleTaskCompletion(nextTask)
                    }) {
                        Image(systemName: nextTask.isCompleted ? "checkmark.circle.fill" : "play.circle.fill")
                            .font(.title)
                            .foregroundColor(nextTask.isCompleted ? .green : nextTask.category.color)
                    }
                }
            } else {
                Text("No upcoming tasks")
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Quick actions view
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.gray)
            
            HStack(spacing: 15) {
                // Log weight button
                NavigationLink(destination: WeightInputView()) {
                    ActionButton(title: "Log Weight", icon: "scalemass", color: .blue)
                }
                
                // Add task button
                NavigationLink(destination: EmptyView()) {
                    ActionButton(title: "Add Task", icon: "plus.circle", color: .green)
                }
                
                // Log water button
                NavigationLink(destination: WaterInputView()) {
                    ActionButton(title: "Log Water", icon: "drop.fill", color: .blue)
                }
            }
        }
    }
    
    // Progress overview
    private var progressOverview: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weekly Progress")
                .font(.headline)
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                // German study progress
                ProgressBar(
                    title: "German Study",
                    progress: calculateProgressForCategory(.german),
                    color: .green
                )
                
                // Exercise progress
                ProgressBar(
                    title: "Exercise",
                    progress: calculateProgressForCategory(.exercise),
                    color: .red
                )
                
                // Coding progress
                ProgressBar(
                    title: "Coding",
                    progress: calculateProgressForCategory(.coding),
                    color: .orange
                )
                
                // Water intake progress
                ProgressBar(
                    title: "Water Intake",
                    progress: min(userDataManager.getTodayWaterIntake() / 3.0, 1.0),
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func getTodayTasks() -> [Task]? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return userDataManager.tasks
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.time < $1.time }
    }
    
    private func getNextTask() -> Task? {
        let tasks = getTodayTasks() ?? []
        
        // First try to find next incomplete task
        if let nextTask = tasks.first(where: { !$0.isCompleted }) {
            return nextTask
        }
        
        // If all tasks are complete, return the last task
        return tasks.last
    }
    
    private func getIconForCategory(_ category: TaskCategory) -> String {
        switch category {
        case .work:
            return "briefcase.fill"
        case .german:
            return "book.fill"
        case .exercise:
            return "figure.run"
        case .coding:
            return "laptop"
        case .recovery:
            return "bed.double.fill"
        }
    }
    
    private func calculateProgressForCategory(_ category: TaskCategory) -> Double {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date()).date!
        
        let tasksForCategory = userDataManager.tasks.filter { task in
            task.category == category &&
            task.date >= startOfWeek &&
            task.date <= Date()
        }
        
        if tasksForCategory.isEmpty {
            return 0.0
        }
        
        let completedTasks = tasksForCategory.filter { $0.isCompleted }
        return Double(completedTasks.count) / Double(tasksForCategory.count)
    }
    
    private func getWeightProgressText() -> String? {
        guard userDataManager.weightHistory.count >= 2 else { return nil }
        
        let sortedEntries = userDataManager.weightHistory.sorted(by: { $0.date > $1.date })
        guard let latest = sortedEntries.first, let previous = sortedEntries[1...].first else { return nil }
        
        let difference = latest.weight - previous.weight
        let sign = difference > 0 ? "+" : ""
        return String(format: "%@%.1fkg", sign, difference)
    }
    
    private func getDayGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour < 12 {
            return "Good morning! Have a great day."
        } else if hour < 17 {
            return "Good afternoon! Hope you're having a productive day."
        } else {
            return "Good evening! Let's review your progress."
        }
    }
}

// MARK: - Helper Components
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ProgressBar: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(userDataManager: UserDataManager())
    }
}
