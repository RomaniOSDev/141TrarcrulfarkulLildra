import SwiftUI

struct ContentView: View {
    @StateObject private var fitnessData = FitnessData()

    var body: some View {
        Group {
            if fitnessData.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(fitnessData)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
