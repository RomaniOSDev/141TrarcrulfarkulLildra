import SwiftUI

// MARK: - Screen backdrop

struct AppMeshBackground: View {
    var body: some View {
        ZStack {
            Color.appBackground
            LinearGradient(
                colors: [
                    Color.appPrimary.opacity(0.17),
                    Color.appBackground.opacity(0.45),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    Color.appAccent.opacity(0.24),
                    Color.appAccent.opacity(0.03),
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 480
            )
            RadialGradient(
                colors: [
                    Color.appPrimary.opacity(0.13),
                    Color.clear,
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Panels & cards

struct AppPanelBackground: View {
    enum Style {
        case elevated
        case outlined
        case inset
    }

    var cornerRadius: CGFloat = 18
    var style: Style = .elevated

    var body: some View {
        switch style {
        case .elevated:
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface,
                                Color.appPrimary.opacity(0.07),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.appAccent.opacity(0.4),
                                Color.appPrimary.opacity(0.14),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.appTextSecondary.opacity(0.14), radius: 22, x: 0, y: 12)
            .shadow(color: Color.appPrimary.opacity(0.1), radius: 6, x: 0, y: 3)

        case .outlined:
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface.opacity(0.94),
                                Color.appPrimary.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.appAccent.opacity(0.55),
                                Color.appPrimary.opacity(0.22),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: Color.appAccent.opacity(0.14), radius: 14, x: 0, y: 6)

        case .inset:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.07),
                            Color.appSurface,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.appTextSecondary.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: Color.appTextSecondary.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }
}

struct AppPrimaryButtonBackground: View {
    var cornerRadius: CGFloat = 14
    var isEnabled: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isEnabled
                            ? [Color.appPrimary, Color.appPrimary.opacity(0.78)]
                            : [Color.appTextSecondary, Color.appTextSecondary.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(isEnabled ? 0.48 : 0),
                            Color.appAccent.opacity(isEnabled ? 0.12 : 0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: (isEnabled ? Color.appPrimary : Color.appTextSecondary).opacity(0.42), radius: 14, x: 0, y: 8)
        .shadow(color: Color.appTextSecondary.opacity(0.14), radius: 4, x: 0, y: 2)
    }
}

struct AppSecondaryOutlineButtonBackground: View {
    var cornerRadius: CGFloat = 14

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.92),
                            Color.appPrimary.opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(0.78),
                            Color.appPrimary.opacity(0.35),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        }
        .shadow(color: Color.appAccent.opacity(0.16), radius: 10, x: 0, y: 4)
    }
}

// MARK: - View helpers

extension View {
    func appMeshScreenBackground() -> some View {
        background { AppMeshBackground() }
    }

    func appChromePanel(style: AppPanelBackground.Style = .elevated, cornerRadius: CGFloat = 18) -> some View {
        background { AppPanelBackground(cornerRadius: cornerRadius, style: style) }
    }

    func appPrimaryButtonChrome(cornerRadius: CGFloat = 14, enabled: Bool = true) -> some View {
        background { AppPrimaryButtonBackground(cornerRadius: cornerRadius, isEnabled: enabled) }
    }

    func appSecondaryOutlineChrome(cornerRadius: CGFloat = 14) -> some View {
        background { AppSecondaryOutlineButtonBackground(cornerRadius: cornerRadius) }
    }
}
