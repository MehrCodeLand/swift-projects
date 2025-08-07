import SwiftUI

struct ScheduleView: View {
    @ObservedObject var userDataManager: UserDataManager
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Weekly calendar header
                WeeklyCalendarHeader(selectedDate: $selectedDate)
                
                // Task list for selected day
                if let tasks = getTasksForSelectedDate(), !tasks.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(tasks) { task in
                                TaskRow(task: task) {
                                    userDataManager.toggleTaskCompletion(task)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No tasks scheduled for this day")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            showingAddTask = true
                        }) {
                            Label("Add Task", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 50)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Schedule")
            .navigationBarItems(trailing: Button(action: {
                showingAddTask = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddTask) {
                TaskInputView(userDataManager: userDataManager, selectedDate: selectedDate)
            }
        }
    }
    
    private func getTasksForSelectedDate() -> [Task]? {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedDate)
        
        let tasks = userDataManager.tasks.filter { task in
            calendar.isDate(calendar.startOfDay(for: task.date), inSameDayAs: selectedDay)
        }
        
        return tasks.sorted { $0.time < $1.time }
    }
}

struct WeeklyCalendarHeader: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    private func dayView(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return VStack(spacing: 4) {
            Text(dayLetters[calendar.component(.weekday, from: date) - 1])
                .font(.caption)
                .foregroundColor(.gray)

            Text("\(calendar.component(.day, from: date))")
                .font(.title3)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
        }
        .frame(width: 40, height: 60)
        .background((isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear)).cornerRadius(8))
        .onTapGesture {
            withAnimation {
                selectedDate = date
            }
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(weekDays, id: \.self) { date in
                    dayView(for: date)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
    
    private var weekDays: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0...6).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]
}

struct TaskRow: View {
    let task: Task
    let toggleCompletion: () -> Void
    
    var body: some View {
        HStack {
            Button(action: toggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.time)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .gray : .primary)
                }
                
                Text(task.duration)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Circle()
                .fill(task.category.color)
                .frame(width: 10, height: 10)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TaskInputView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Environment(\.presentationMode) var presentationMode
    
    var selectedDate: Date
    
    @State private var title = ""
    @State private var time = Date()
    @State private var duration = "1h"
    @State private var selectedCategory: TaskCategory = .work
    
    private let durationOptions = ["30m", "1h", "1h 30m", "2h", "2h 30m", "3h"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    
                    Picker("Duration", selection: $duration) {
                        ForEach(durationOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("Work").tag(TaskCategory.work)
                        Text("German").tag(TaskCategory.german)
                        Text("Exercise").tag(TaskCategory.exercise)
                        Text("Coding").tag(TaskCategory.coding)
                        Text("Recovery").tag(TaskCategory.recovery)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button("Add Task") {
                        addTask()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("New Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func addTask() {
        // Format time string (e.g., "14:30")
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: time)
        
        // Create date by combining selected date with time
        let calendar = Calendar.current
        let taskDate = calendar.date(bySettingHour: calendar.component(.hour, from: time),
                                     minute: calendar.component(.minute, from: time),
                                     second: 0,
                                     of: selectedDate) ?? selectedDate
        
        // Create new task
        let task = Task(
            title: title,
            time: timeString,
            duration: duration,
            category: selectedCategory,
            isCompleted: false,
            date: taskDate
        )
        
        // Add to data manager
        userDataManager.addTask(task)
        
        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView(userDataManager: UserDataManager())
    }
}
