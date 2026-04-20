import Combine
import Foundation
import SwiftUI

enum RootTab: Hashable {
    case home
    case training
    case progress
}

@MainActor
final class TabRouter: ObservableObject {
    @Published var selection: RootTab = .home
}
