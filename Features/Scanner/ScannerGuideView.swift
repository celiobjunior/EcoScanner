import SwiftUI

// MARK: - ScannerGuideView

struct ScannerGuideView: View {
    let isActive: Bool

    private let cornerLength: CGFloat = 70
    private let lineWidth: CGFloat = 10

    var body: some View {
        ScannerCornerFrameShape(cornerLength: cornerLength)
            .stroke(
                isActive ? Color.ecoLight : Color.ecoSmoke.opacity(0.95),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .overlay {
                ScannerCornerFrameShape(cornerLength: cornerLength)
                    .stroke(
                        isActive ? Color.ecoPrimary.opacity(0.42) : .clear,
                        style: StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .blur(radius: isActive ? 1.2 : 0)
            }
            .compositingGroup()
            .shadow(color: .black.opacity(isActive ? 0.24 : 0.14), radius: 6, y: 2)
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Shape

private struct ScannerCornerFrameShape: Shape {
    let cornerLength: CGFloat

    func path(in rect: CGRect) -> Path {
        let clampedCorner = max(0, min(cornerLength, min(rect.width, rect.height) / 2))
        var path = Path()

        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)

        // Top-left corner
        path.move(to: CGPoint(x: topLeft.x + clampedCorner, y: topLeft.y))
        path.addLine(to: topLeft)
        path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y + clampedCorner))

        // Top-right corner
        path.move(to: CGPoint(x: topRight.x - clampedCorner, y: topRight.y))
        path.addLine(to: topRight)
        path.addLine(to: CGPoint(x: topRight.x, y: topRight.y + clampedCorner))

        // Bottom-left corner
        path.move(to: CGPoint(x: bottomLeft.x + clampedCorner, y: bottomLeft.y))
        path.addLine(to: bottomLeft)
        path.addLine(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - clampedCorner))

        // Bottom-right corner
        path.move(to: CGPoint(x: bottomRight.x - clampedCorner, y: bottomRight.y))
        path.addLine(to: bottomRight)
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y - clampedCorner))

        return path
    }
}
