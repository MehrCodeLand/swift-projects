import SwiftUI

struct HabitsView: View {
    @ObservedObject var userDataManager: UserDataManager
    @State private var showingAddHabit = false
    @State private var selectedFilter: HabitFilter = .all
    
    enum HabitFilter {
        case all, morning, daily, evening
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter tabs
                HStack(spacing: 0) {
                    ForEach([HabitFilter.all, .morning, .daily, .evening], id: \.self) { filter in
                        Button(action: {
                            withAnimation {
                                selectedFilter = filter
                            }
                        }) {
                            Text(filterName(filter))
                                .font(.subheadline)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity)
                                .background(selectedFilter == filter ? Color.blue.opacity(0.1) : Color.clear)
                                .foregroundColor(selectedFilter == filter ? .blue : .gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                    .padding(.top, 8)
                
                // Habits list
                if filteredHabits.isEmpty {
                    emptyHabitsView
                } else {
                    List {
                        if selectedFilter == .all {
                            if let morningHabits = habitsForCategory("Morning"), !morningHabits.isEmpty {
                                Section(header: Text("Morning Routine")) {
                                    ForEach(morningHabits) { habit in
                                        HabitRow(habit: habit) {
                                            userDataManager.toggleHabit(habit)
                                        }
                                    }
                                }
                            }
                            
                            if let dailyHabits = habitsForCategory("Daily"), !dailyHabits.isEmpty {
                                Section(header: Text("Daily Goals")) {
                                    ForEach(dailyHabits) { habit in
                                        HabitRow(habit: habit) {
                                            userDataManager.toggleHabit(habit)
                                        }
                                    }
                                }
                            }
                            
                            if let eveningHabits = habitsForCategory("Evening"), !eveningHabits.isEmpty {
                                Section(header: Text("Evening Routine")) {
                                    ForEach(eveningHabits) { habit in
                                        HabitRow(habit: habit) {
                                            userDataManager.toggleHabit(habit)
                                        }
                                    }
                                }
                            }
                        } else {
                            ForEach(filteredHabits) { habit in
                                HabitRow(habit: habit) {
                                    userDataManager.toggleHabit(habit)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarItems(trailing: Button(action: {
                showingAddHabit = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddHabit) {
                HabitInputView(userDataManager: userDataManager)
            }
        }
    }
    
    private var emptyHabitsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 60)
            
            Text("No habits found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Add habits to track your daily routines")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingAddHabit = true
            }) {
                Label("Add Habit", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
    
    private var filteredHabits: [Habit] {
        switch selectedFilter {
        case .all:
            return userDataManager.habits
        case .morning:
            return userDataManager.habits.filter { $0.category == "Morning" }
        case .daily:
            return userDataManager.habits.filter { $0.category == "Daily" }
        case .evening:
            return userDataManager.habits.filter { $0.category == "Evening" }
        }
    }
    
    private func habitsForCategory(_ category: String) -> [Habit]? {
        let habits = userDataManager.habits.filter { $0.category == category }
        return habits.isEmpty ? nil : habits
    }
    
    private func filterName(_ filter: HabitFilter) -> String {
        switch filter {
        case .all: return "All"
        case .morning: return "Morning"
        case .daily: return "Daily"
        case .evening: return "Evening"
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    let toggleCompletion: () -> Void
    
    var body: some View {
        HStack {
            Button(action: toggleCompletion) {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(habit.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(habit.title)
                .strikethrough(habit.isCompleted)
                .foregroundColor(habit.isCompleted ? .gray : .primary)
            
            Spacer()
            
            Group {
                if habit.isDaily {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                Text(habit.category)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor(habit.category).opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Morning": return .blue
        case "Daily": return .green
        case "Evening": return .purple
        default: return .gray
        }
    }
}

struct HabitInputView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var category = "Daily"
    @State private var isDaily = true
    
    private let categories = ["Morning", "Daily", "Evening"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Habit Details")) {
                    TextField("Habit title", text: $title)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Repeats daily", isOn: $isDaily)
                }
                
                Section {
                    Button("Add Habit") {
                        addHabit()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func addHabit() {
        // Create new habit
        let habit = Habit(
            title: title,
            isCompleted: false,
            isDaily: isDaily,
            category: category
        )
        
        // Add to data manager
        userDataManager.addHabit(habit)
        
        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
}

struct HabitsView_Previews: PreviewProvider {
    static var previews: some View {
        HabitsView(userDataManager: UserDataManager())
    }
}
