import SwiftUI

struct WeightTrackerView: View {
    @ObservedObject var userDataManager: UserDataManager
    
    var body: some View {
        NavigationView {
            Text("Weight Tracker View")
                .navigationTitle("Health Tracker")
        }
    }
}

// MARK: - Weight Input View
struct WeightInputView: View {
    @EnvironmentObject var userDataManager: UserDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var weightInput = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Weight Entry")) {
                    TextField("Enter weight in kg", text: $weightInput)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section {
                    Button("Save") {
                        if let weight = Double(weightInput) {
                            userDataManager.addWeightEntry(weight: weight)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                    .disabled(weightInput.isEmpty || Double(weightInput) == nil)
                }
            }
            .navigationTitle("Add Weight")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Water Input View
struct WaterInputView: View {
    @EnvironmentObject var userDataManager: UserDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var waterInput = ""
    @State private var selectedAmount: Double?
    
    private let predefinedAmounts: [Double] = [0.25, 0.33, 0.5, 0.75, 1.0, 1.5]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Quick Add")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(predefinedAmounts, id: \.self) { amount in
                                Button(action: {
                                    selectedAmount = amount
                                    waterInput = String(format: "%.2f", amount)
                                }) {
                                    VStack(spacing: 8) {
                                        Text("\(amount, specifier: "%.2g") L")
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "drop.fill")
                                            .font(.title2)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                    .frame(height: 80)
                                    .background(selectedAmount == amount ? Color.blue.opacity(0.2) : Color(.systemGray6))
                                    .foregroundColor(selectedAmount == amount ? .blue : .primary)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                }
                
                Section(header: Text("Custom Amount")) {
                    TextField("Enter water amount in liters", text: $waterInput)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button("Add Water") {
                        if let amount = Double(waterInput) {
                            userDataManager.addWaterIntake(amount: amount)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                    .disabled(waterInput.isEmpty || Double(waterInput) == nil)
                }
            }
            .navigationTitle("Add Water Intake")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Step Input View
struct StepInputView: View {
    @EnvironmentObject var userDataManager: UserDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var stepInput = ""
    @State private var selectedAmount: Int?
    @State private var date = Date()
    
    private let predefinedAmounts: [Int] = [1000, 2000, 5000, 7500, 10000]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Quick Add")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(predefinedAmounts, id: \.self) { amount in
                                Button(action: {
                                    selectedAmount = amount
                                    stepInput = String(amount)
                                }) {
                                    VStack(spacing: 8) {
                                        Text("\(amount)")
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "figure.walk")
                                            .font(.title2)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                    .frame(height: 80)
                                    .background(selectedAmount == amount ? Color.green.opacity(0.2) : Color(.systemGray6))
                                    .foregroundColor(selectedAmount == amount ? .green : .primary)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                }
                
                Section(header: Text("Custom Amount")) {
                    TextField("Enter steps", text: $stepInput)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Add Steps") {
                        if let steps = Int(stepInput) {
                            userDataManager.addSteps(count: steps)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                    .disabled(stepInput.isEmpty || Int(stepInput) == nil)
                }
            }
            .navigationTitle("Add Steps")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Sleep Input View
struct SleepInputView: View {
    @EnvironmentObject var userDataManager: UserDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var hours: Double = 7.5
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sleep Hours")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Stepper(value: $hours, in: 0...12, step: 0.5) {
                        HStack {
                            Text("Hours")
                            Spacer()
                            Text("\(hours, specifier: "%.1f")")
                                .foregroundColor(.purple)
                        }
                    }
                    
                    // Sleep duration slider
                    VStack(alignment: .leading) {
                        Text("Sleep Duration")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text("0h")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Slider(value: $hours, in: 0...12, step: 0.5)
                                .accentColor(.purple)
                            
                            Text("12h")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Sleep quality indicator
                    HStack {
                        Text("Quality")
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(0..<getSleepQualityStars(hours: hours), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(getSleepQualityColor(hours: hours))
                            }
                            ForEach(0..<(5-getSleepQualityStars(hours: hours)), id: \.self) { _ in
                                Image(systemName: "star")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Save Sleep Entry") {
                        userDataManager.addSleepEntry(hours: hours)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.purple)
                }
            }
            .navigationTitle("Add Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // Helper functions to determine sleep quality
    private func getSleepQualityColor(hours: Double) -> Color {
        if hours < 6 {
            return .red
        } else if hours < 7 {
            return .orange
        } else if hours < 9 {
            return .green
        } else {
            return .purple
        }
    }
    
    private func getSleepQualityStars(hours: Double) -> Int {
        if hours < 6 {
            return 1
        } else if hours < 7 {
            return 2
        } else if hours < 9 {
            return 4
        } else {
            return 5
        }
    }
}

// MARK: - Calorie Input View
struct CalorieInputView: View {
    @EnvironmentObject var userDataManager: UserDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var calorieInput = ""
    @State private var description = ""
    @State private var selectedMeal = "Breakfast"
    @State private var selectedAmount: Int?
    
    private let predefinedAmounts: [Int] = [100, 250, 500, 750, 1000]
    private let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snack", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meal Details")) {
                    Picker("Meal Type", selection: $selectedMeal) {
                        ForEach(mealOptions, id: \.self) { meal in
                            Text(meal).tag(meal)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Description (e.g., pasta)", text: $description)
                }
                
                Section(header: Text("Quick Add")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(predefinedAmounts, id: \.self) { amount in
                                Button(action: {
                                    selectedAmount = amount
                                    calorieInput = String(amount)
                                }) {
                                    VStack(spacing: 8) {
                                        Text("\(amount)")
                                            .fontWeight(.semibold)
                                        
                                        Text("calories")
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                    .frame(height: 80)
                                    .background(selectedAmount == amount ? Color.orange.opacity(0.2) : Color(.systemGray6))
                                    .foregroundColor(selectedAmount == amount ? .orange : .primary)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                }
                
                Section(header: Text("Calories")) {
                    TextField("Enter calories", text: $calorieInput)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Add Calorie Entry") {
                        if let calories = Int(calorieInput) {
                            let mealDescription = description.isEmpty ? selectedMeal : "\(selectedMeal): \(description)"
                            userDataManager.addCalorieEntry(calories: calories, description: mealDescription)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.orange)
                    .disabled(calorieInput.isEmpty || Int(calorieInput) == nil)
                }
            }
            .navigationTitle("Add Calories")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
