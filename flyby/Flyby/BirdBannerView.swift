import SwiftUI

/// A bird towing a banner, flying left to right across the screen.
struct BirdBannerView: View {
    let message: String
    let onFinished: () -> Void

    /// 0 = fully offscreen left, 1 = fully offscreen right.
    @State private var flightProgress: CGFloat = 0
    @State private var zigzagging = false
    @State private var flapping = false

    private let flightDuration: Double = 9

    var body: some View {
        GeometryReader { geo in
            birdWithBanner
                .offset(y: zigzagging ? -90 : 90) // zigzag around the center line
                .position(
                    x: -320 + (geo.size.width + 640) * flightProgress,
                    y: geo.size.height * 0.5
                )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            // Linear timing gives sharp zigzag turns instead of a smooth wave.
            withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: true)) {
                zigzagging = true
            }
            withAnimation(.easeInOut(duration: 0.22).repeatForever(autoreverses: true)) {
                flapping = true
            }
            withAnimation(.linear(duration: flightDuration)) {
                flightProgress = 1
            } completion: {
                onFinished()
            }
        }
    }

    private var birdWithBanner: some View {
        HStack(spacing: 0) {
            Text(message)
                .font(.title3.bold())
                .lineLimit(1)
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.yellow.gradient, in: Capsule())
                .overlay(Capsule().strokeBorder(.orange, lineWidth: 2))

            // Tow rope between banner and bird.
            Rectangle()
                .fill(.orange)
                .frame(width: 28, height: 2)

            BirdView(flapping: flapping)
        }
        .fixedSize()
        .shadow(radius: 3)
    }
}

/// A cartoon bird facing right, with a wing that flaps.
private struct BirdView: View {
    let flapping: Bool

    var body: some View {
        ZStack {
            // Tail feathers
            Triangle()
                .fill(.teal)
                .frame(width: 20, height: 16)
                .rotationEffect(.degrees(-90))
                .offset(x: -30, y: 0)

            // Body
            Ellipse()
                .fill(.teal.gradient)
                .frame(width: 52, height: 32)

            // Head
            Circle()
                .fill(.teal)
                .frame(width: 24, height: 24)
                .offset(x: 24, y: -10)

            // Beak
            Triangle()
                .fill(.orange)
                .frame(width: 14, height: 12)
                .rotationEffect(.degrees(90))
                .offset(x: 40, y: -9)

            // Eye
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .offset(x: 28, y: -13)
            Circle()
                .fill(.black)
                .frame(width: 4, height: 4)
                .offset(x: 29, y: -13)

            // Wing — flaps by rotating around its trailing edge.
            Ellipse()
                .fill(Color(hue: 0.52, saturation: 0.75, brightness: 0.45))
                .frame(width: 32, height: 18)
                .rotationEffect(.degrees(flapping ? -55 : 20), anchor: .trailing)
                .offset(x: -8, y: -4)
        }
        .frame(width: 96, height: 64)
        .rotationEffect(.degrees(flapping ? -4 : 4)) // slight glide tilt
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    BirdBannerView(message: "Standup — in 5 minutes") {}
        .frame(width: 800, height: 300)
}
