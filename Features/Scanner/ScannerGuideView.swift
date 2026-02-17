import SwiftUI

// MARK: - ScannerGuideView

struct ScannerGuideView: View {
    let isActive: Bool

    private let cornerLength: CGFloat = .size.scannerGuideCornerLength
    private let lineWidth: CGFloat = .lineWidth.scannerGuide

    var body: some View {
        ScannerCornerFrameShape(cornerLength: cornerLength)
            .stroke(
                isActive ? Color.ecoLight : Color.ecoSmoke.opacity(Double.opacity.almostOpaque),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .overlay {
                ScannerCornerFrameShape(cornerLength: cornerLength)
                    .stroke(
                        isActive ? Color.ecoPrimary.opacity(Double.opacity.scannerFocus) : .clear,
                        style: StrokeStyle(
                            lineWidth: .lineWidth.regular,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .blur(radius: isActive ? .blur.subtle : .spacing.none)
            }
            .compositingGroup()
            .shadow(
                color: .black.opacity(isActive ? Double.opacity.overlaySoft : Double.opacity.track),
                radius: .shadow.mediumRadius,
                y: .shadow.smallYOffset
            )
            .animation(.easeInOut(duration: Double.duration.fast), value: isActive)
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
