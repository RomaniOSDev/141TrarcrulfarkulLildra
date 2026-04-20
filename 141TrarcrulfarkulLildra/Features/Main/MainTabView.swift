import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var fitness: FitnessData
    @StateObject private var tabRouter = TabRouter()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AppMeshBackground()
                switch tabRouter.selection {
                case .home:
                    HomeView()
                case .training:
                    TrainingPlansContainerView()
                case .progress:
                    ProgressHubView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selection: $tabRouter.selection)
        }
        .environmentObject(tabRouter)
    }
}

private struct CustomTabBar: View {
    @Binding var selection: RootTab

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.appTextSecondary.opacity(0.14), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 12)

            HStack(spacing: 0) {
                tabItem(.home, title: "Home") {
                    DashboardTabGlyph(selected: selection == .home)
                }
                tabItem(.training, title: "Training Plans") {
                    TrainingTabGlyph(selected: selection == .training)
                }
                tabItem(.progress, title: "Progress") {
                    ProgressTabGlyph(selected: selection == .progress)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    Color.appSurface
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.08), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
        }
        .shadow(color: Color.appTextSecondary.opacity(0.2), radius: 26, x: 0, y: -12)
        .shadow(color: Color.appPrimary.opacity(0.12), radius: 10, x: 0, y: -5)
    }

    private func tabItem(_ tab: RootTab, title: String, @ViewBuilder glyph: () -> some View) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 6) {
                glyph()
                    .frame(width: 28, height: 28)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selection == tab ? Color.appPrimary : Color.appTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

private struct DashboardTabGlyph: View {
    let selected: Bool
    private var color: Color { selected ? Color.appPrimary : Color.appTextSecondary }

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = size.width / 4
            for row in 0..<2 {
                for col in 0..<2 {
                    let rect = CGRect(
                        x: CGFloat(col) * step + 2,
                        y: CGFloat(row) * step + 2,
                        width: step - 4,
                        height: step - 4
                    )
                    let path = Path(roundedRect: rect, cornerRadius: 3)
                    context.fill(path, with: .color(color.opacity(row == 0 ? 1.0 : 0.75)))
                }
            }
        }
    }
}

private struct TrainingTabGlyph: View {
    let selected: Bool
    private var color: Color { selected ? Color.appPrimary : Color.appTextSecondary }

    var body: some View {
        Canvas { context, size in
            let bar = Path { path in
                path.move(to: CGPoint(x: 4, y: size.height - 6))
                path.addLine(to: CGPoint(x: size.width - 4, y: size.height - 6))
            }
            context.stroke(bar, with: .color(color), lineWidth: 4)

            let arc = Path { path in
                path.addArc(
                    center: CGPoint(x: size.width * 0.5, y: size.height * 0.55),
                    radius: size.width * 0.32,
                    startAngle: .degrees(200),
                    endAngle: .degrees(-20),
                    clockwise: true
                )
            }
            context.stroke(arc, with: .color(color.opacity(0.9)), lineWidth: 4)
        }
    }
}

private struct ProgressTabGlyph: View {
    let selected: Bool
    private var color: Color { selected ? Color.appPrimary : Color.appTextSecondary }

    var body: some View {
        Canvas { context, size in
            let trend = Path { path in
                path.move(to: CGPoint(x: 4, y: size.height - 6))
                path.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.55))
                path.addLine(to: CGPoint(x: size.width * 0.65, y: size.height * 0.35))
                path.addLine(to: CGPoint(x: size.width - 4, y: 8))
            }
            context.stroke(trend, with: .color(color), lineWidth: 4)
        }
    }
}
