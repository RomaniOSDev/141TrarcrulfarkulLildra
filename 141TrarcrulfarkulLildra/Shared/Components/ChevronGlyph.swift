import SwiftUI

struct ChevronGlyph: View {
    var body: some View {
        let strokeColor: Color = Color.appAccent
        return Canvas { context, size in
            let path = Path { p in
                p.move(to: CGPoint(x: 4, y: size.height * 0.35))
                p.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.65))
                p.addLine(to: CGPoint(x: size.width - 4, y: size.height * 0.35))
            }
            context.stroke(path, with: .color(strokeColor), lineWidth: 3)
        }
        .frame(width: 18, height: 18)
    }
}
