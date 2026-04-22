import SwiftUI

// MARK: - Screen backdrop

struct AppMeshBackground: View {
    var body: some View {
        ZStack {
            baseVerticalAtmosphere
            diagonalColorWash
            topAccentBloom
            leadingPrimaryHaze
            bottomAuroraBand
            topSpecularSheen
            subtleGridTexture
        }
        .ignoresSafeArea()
    }

    /// Lighter top → body → soft primary tint at bottom (readable, layered).
    private var baseVerticalAtmosphere: some View {
        LinearGradient(
            colors: [
                Color.appSurface,
                Color.appBackground,
                Color.appBackground,
                Color.appPrimary.opacity(0.07),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var diagonalColorWash: some View {
        LinearGradient(
            colors: [
                Color.appPrimary.opacity(0.14),
                Color.appBackground.opacity(0.2),
                Color.appAccent.opacity(0.1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var topAccentBloom: some View {
        RadialGradient(
            colors: [
                Color.appAccent.opacity(0.38),
                Color.appAccent.opacity(0.1),
                Color.clear,
            ],
            center: UnitPoint(x: 0.9, y: 0.05),
            startRadius: 10,
            endRadius: 520
        )
    }

    private var leadingPrimaryHaze: some View {
        RadialGradient(
            colors: [
                Color.appPrimary.opacity(0.26),
                Color.appPrimary.opacity(0.05),
                Color.clear,
            ],
            center: UnitPoint(x: 0.04, y: 0.38),
            startRadius: 20,
            endRadius: 420
        )
    }

    private var bottomAuroraBand: some View {
        RadialGradient(
            colors: [
                Color.appPrimary.opacity(0.2),
                Color.appAccent.opacity(0.12),
                Color.clear,
            ],
            center: UnitPoint(x: 0.55, y: 1.05),
            startRadius: 40,
            endRadius: 580
        )
    }

    private var topSpecularSheen: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.42),
                Color.white.opacity(0.06),
                Color.clear,
            ],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.42)
        )
        .allowsHitTesting(false)
    }

    private var subtleGridTexture: some View {
        Canvas { context, size in
            let step: CGFloat = 32
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(Color.appPrimary.opacity(0.045)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
        .blendMode(.multiply)
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
