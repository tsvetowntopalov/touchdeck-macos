import CoreGraphics
import Foundation

struct FingerDot: Identifiable, Equatable {
    let id: Int32
    let point: CGPoint // normalized, origin top-left
}

/// Observable UI state shared by the router (writer) and the SwiftUI deck (reader).
final class DeckState: ObservableObject {
    @Published var isVisible = false
    @Published var fingers: [FingerDot] = []
    @Published var hoveredKeys: Set<DeckKey> = []
    @Published var flashKey: DeckKey?
    @Published var sliderValues: [SliderID: Double] = [
        .brightness: 0.5,
        .volume: 0.5,
        .custom: 0.5,
    ]
}
