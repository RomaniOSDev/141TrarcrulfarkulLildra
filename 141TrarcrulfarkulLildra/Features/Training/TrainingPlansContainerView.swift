import SwiftUI

struct TrainingPlansContainerView: View {
    @State private var path: [TrainingDestination] = []

    var body: some View {
        NavigationStack(path: $path) {
            SessionSelectionView(path: $path)
                .navigationDestination(for: TrainingDestination.self) { destination in
                    TrainingDestinationHost(destination: destination, path: $path)
                }
        }
        .background(Color.clear)
    }
}
