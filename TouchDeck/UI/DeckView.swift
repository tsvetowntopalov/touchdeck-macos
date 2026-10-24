import SwiftUI

struct DeckView: View {
    @ObservedObject var state: DeckState

    var body: some View {
        let size = DeckLayout.panelSize

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)

            ForEach(DeckLayout.controls) { control in
                controlView(control)
                    .frame(width: control.rect.width * size.width,
                           height: control.rect.height * size.height)
                    .position(x: control.rect.midX * size.width,
                              y: control.rect.midY * size.height)
            }

            ForEach(state.fingers) { finger in
                FingerDotView()
                    .position(x: finger.point.x * size.width, y: finger.point.y * size.height)
            }
        }
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func controlView(_ control: DeckControl) -> some View {
        switch control.kind {
        case .slider(let slider):
            SliderView(slider: slider, value: state.sliderValues[slider] ?? 0)
        case .key(let key):
            KeyView(key: key,
                    hovered: state.hoveredKeys.contains(key),
                    flashing: state.flashKey == key)
        }
    }
}

private struct SliderView: View {
    let slider: SliderID
    let value: Double

    var body: some View {
        GeometryReader { geo in
            let trackWidth = min(geo.size.width * 0.55, 56)
            ZStack(alignment: .bottom) {
                Capsule().fill(.white.opacity(0.12))
                Capsule()
                    .fill(.white.opacity(0.88))
                    .frame(height: max(trackWidth, geo.size.height * CGFloat(value)))
            }
            .frame(width: trackWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .top) {
            Text("\(Int((value * 100).rounded()))%")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.75))
                .offset(y: -26)
        }
        .overlay(alignment: .bottom) {
            Image(systemName: slider.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .offset(y: 28)
        }
    }
}

private struct KeyView: View {
    let key: DeckKey
    let hovered: Bool
    let flashing: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(fill)
            .overlay { label.foregroundStyle(.white) }
            .scaleEffect(flashing ? 0.93 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: flashing)
            .animation(.easeOut(duration: 0.08), value: hovered)
    }

    private var fill: Color {
        if flashing { return .white.opacity(0.55) }
        if key == .backspace { return .blue.opacity(hovered ? 1 : 0.8) }
        return .white.opacity(hovered ? 0.3 : 0.12)
    }

    @ViewBuilder
    private var label: some View {
        if let symbol = key.symbol {
            Image(systemName: symbol).font(.system(size: 20, weight: .semibold))
        } else {
            Text(key.label ?? "").font(.system(size: 26, weight: .medium, design: .rounded))
        }
    }
}

private struct FingerDotView: View {
    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.18)).frame(width: 40, height: 40)
            Circle().fill(.white).frame(width: 16, height: 16)
                .shadow(color: .black.opacity(0.35), radius: 4)
        }
        .allowsHitTesting(false)
    }
}
