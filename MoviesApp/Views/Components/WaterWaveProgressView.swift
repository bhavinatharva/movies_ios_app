import SwiftUI

struct WaterWaveProgressView: View {
    let progress: Double
    var waveHeight: CGFloat = 0.05
    var waveFrequency: CGFloat = 1.5
    var waveSpeed: Double = 2.0
    var color: Color = .accentColor
    
    @State private var phase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
                
                // Water wave
                WaterWave(progress: progress, phase: phase, waveHeight: waveHeight, waveFrequency: waveFrequency)
                    .fill(color.opacity(0.8))
                    .clipShape(Circle())
                
                // Percentage Text
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .onAppear {
            withAnimation(.linear(duration: waveSpeed).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct WaterWave: Shape {
    var progress: Double
    var phase: Double
    var waveHeight: CGFloat
    var waveFrequency: CGFloat
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(progress, phase) }
        set {
            progress = newValue.first
            phase = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let progressHeight = height * (1 - progress)
        let actualWaveHeight = progress <= 0.01 || progress >= 0.99 ? 0 : height * waveHeight
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: progressHeight))
        
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 2 * waveFrequency + phase)
            let y = progressHeight + sine * actualWaveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}
