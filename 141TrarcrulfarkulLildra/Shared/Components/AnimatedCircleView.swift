import SwiftUI

struct AnimatedCircleView: View {
    var progress: Double
    var lineWidth: CGFloat = 14

    @State private var rotation: Double = 0

    var body: some View {
        let secondaryTrack: Color = Color.appTextSecondary
        let accentSoftRing: Color = Color.appAccent
        let accentStroke: Color = Color.appAccent
        let primaryStroke: Color = Color.appPrimary

        return ZStack {
            Circle()
                .strokeBorder(secondaryTrack.opacity(0.35), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [accentStroke, primaryStroke]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)

            Circle()
                .strokeBorder(accentSoftRing.opacity(0.35), lineWidth: lineWidth * 0.45)
                .scaleEffect(0.72)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}
