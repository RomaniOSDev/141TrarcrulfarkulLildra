import SwiftUI

struct StarRowView: View {
    let filled: Int
    let animate: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                StarShape()
                    .fill(index < filled ? Color.appAccent : Color.appTextSecondary.opacity(0.35))
                    .frame(width: 34, height: 34)
                    .shadow(color: index < filled ? Color.appAccent.opacity(0.55) : .clear, radius: animate ? 10 : 0)
                    .scaleEffect(animate && index < filled ? 1.05 : 1.0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.65).delay(Double(index) * 0.08), value: filled)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Stars \(filled) of three"))
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        let points = 5
        for index in 0..<(points * 2) {
            let angle = CGFloat(index) * .pi / CGFloat(points) - .pi / 2
            let r = index.isMultiple(of: 2) ? radius : radius * 0.45
            let point = CGPoint(
                x: center.x + cos(angle) * r,
                y: center.y + sin(angle) * r
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
