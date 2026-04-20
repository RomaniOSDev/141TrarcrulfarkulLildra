import Foundation
import UIKit

enum AppExternalLink: String, CaseIterable {
    case privacyPolicy = "https://trarcrulfarkullildra141.site/privacy/115"
    case termsOfUse = "https://trarcrulfarkullildra141.site/terms/115"

    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfUse: return "Terms of Use"
        }
    }

    func openInBrowser() {
        if let url = URL(string: rawValue) {
            UIApplication.shared.open(url)
        }
    }
}
