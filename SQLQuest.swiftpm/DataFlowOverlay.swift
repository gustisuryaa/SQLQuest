import SwiftUI

// MARK: - DataFlowOverlay
// Animates data "particles" flowing from source tables into the active
// region of the Venn diagram when the JOIN type changes.

struct DataFlowOverlay: View {
    let joinType: JoinType
    @State private var particles: [FlowParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    FlowParticleView(particle: p, containerSize: geo.size)
                        .id(p.id)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: joinType) { _ in respawn() }
        .onAppear { respawn() }
    }

    private func respawn() {
        withAnimation(.easeOut(duration: 0.12)) { particles = [] }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            particles = makeParticles(for: joinType)
        }
    }

    private func makeParticles(for type: JoinType) -> [FlowParticle] {
        switch type {
        case .inner:
            return [
                FlowParticle(label: "Alice",    color: .blue,   side: .left,  delay: 0.00),
                FlowParticle(label: "iOS Club", color: .orange, side: .right, delay: 0.14)
            ]
        case .left:
            return [
                FlowParticle(label: "Alice", color: .blue,             side: .left, delay: 0.00),
                FlowParticle(label: "Bob",   color: .blue.opacity(0.6), side: .left, delay: 0.18),
                FlowParticle(label: "Carol", color: .blue.opacity(0.4), side: .left, delay: 0.36)
            ]
        case .right:
            return [
                FlowParticle(label: "iOS Club",   color: .orange,             side: .right, delay: 0.00),
                FlowParticle(label: "Robotics",   color: .orange.opacity(0.6), side: .right, delay: 0.18),
                FlowParticle(label: "Chess Club", color: .orange.opacity(0.4), side: .right, delay: 0.36)
            ]
        }
    }
}

// MARK: - FlowParticle Model

enum ParticleSide { case left, right }

struct FlowParticle: Identifiable {
    let id    = UUID()
    let label : String
    let color : Color
    let side  : ParticleSide
    let delay : Double
}

// MARK: - FlowParticleView

struct FlowParticleView: View {
    let particle      : FlowParticle
    let containerSize : CGSize

    @State private var progress : CGFloat = 0
    @State private var visible  : Bool    = false

    // Horizontal origin near the outer edge of the respective circle
    var startX: CGFloat { particle.side == .left ? containerSize.width * 0.16 : containerSize.width * 0.84 }
    var endX  : CGFloat { containerSize.width * 0.50 }
    var baseY : CGFloat { containerSize.height * 0.50 }

    var curX: CGFloat { startX + (endX - startX) * progress }
    var curY: CGFloat {
        let arc = sin(progress * .pi) * -16   // gentle upward arc
        return baseY + arc
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(particle.color.opacity(0.25))
                .frame(width: 16, height: 16)
            Circle()
                .fill(particle.color)
                .frame(width: 8, height: 8)
                .shadow(color: particle.color, radius: 5)
            Text(particle.label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(particle.color).cornerRadius(6)
                .offset(y: -20)
        }
        .position(x: curX, y: curY)
        .opacity(visible ? max(0, 1.0 - Double(progress) * 0.8) : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.14).delay(particle.delay))  { visible  = true }
            withAnimation(.easeInOut(duration: 0.6).delay(particle.delay + 0.1)) { progress = 1.0 }
        }
    }
}
