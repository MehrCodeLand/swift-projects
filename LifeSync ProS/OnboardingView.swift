import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userDataManager: UserDataManager
    @State private var name: String = ""
    @State private var initialWeight: String = ""
    @State private var targetWeight: String = ""
    @State private var currentStep = 0
    
    var body: some View {
        VStack {
            // Progress indicator
            HStack(spacing: 10) {
                ForEach(0..<3) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            // Step content
            if currentStep == 0 {
                welcomeStep
            } else if currentStep == 1 {
                nameStep
            } else {
                weightStep
            }
            
            Spacer()
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(currentStep == 2 ? "Get Started" : "Next") {
                    if currentStep == 2 {
                        completeOnboarding()
                    } else {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                }
                .padding()
                .disabled(isNextButtonDisabled)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding()
    }
    
    // Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.and.chart.bar")
                .font(.system(size: 70))
                .foregroundColor(.blue)
                .padding()
            
            Text("Welcome to LifeSync Pro")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your all-in-one personal tracking and habit management app")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
        }
    }
    
    // Step 2: Name
    private var nameStep: some View {
        VStack(spacing: 20) {
            Text("What should we call you?")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Your Name", text: $name)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    // Step 3: Weight goals
    private var weightStep: some View {
        VStack(spacing: 20) {
            Text("Set your weight goals")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading) {
                Text("Current weight (kg)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Current weight", text: $initialWeight)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text("Target weight (kg)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Target weight", text: $targetWeight)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            Text("You can always change these later in settings")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top)
        }
    }
    
    private var isNextButtonDisabled: Bool {
        if currentStep == 1 && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        if currentStep == 2 {
            let isInitialWeightValid = Double(initialWeight) != nil || initialWeight.isEmpty
            let isTargetWeightValid = Double(targetWeight) != nil || targetWeight.isEmpty
            return !isInitialWeightValid || !isTargetWeightValid
        }
        return false
    }
    
    private func completeOnboarding() {
        let user = User(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            targetWeight: Double(targetWeight),
            initialWeight: Double(initialWeight)
        )
        
        userDataManager.setUser(user)
        
        // Add initial weight entry if provided
        if let initialWeight = Double(initialWeight) {
            userDataManager.addWeightEntry(weight: initialWeight)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(UserDataManager())
    }
}
