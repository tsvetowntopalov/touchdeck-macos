import CoreGraphics
import Foundation

/// Turns raw trackpad frames into deck interactions:
///  - a finger that lands on a slider drags it (absolute position, like a touchscreen),
///  - a quick tap on a key fires it,
///  - a physical click fires the key under the most recent finger.
final class TouchRouter {
    static let tapMaxDuration: Double = 0.25   // seconds
    static let tapMaxDistance: CGFloat = 0.03  // normalized trackpad units
    static let sliderEpsilon: Double = 0.004   // skip no-op system calls

    private struct Track {
        let start: CGPoint
        let startTime: Double
        var last: CGPoint
        let control: DeckControl?
        var consumed = false
    }

    private let state: DeckState
    private let actions: DeckActions
    private var tracks: [Int32: Track] = [:]

    var isEnabled = false {
        didSet { if !isEnabled { reset() } }
    }

    init(state: DeckState, actions: DeckActions) {
        self.state = state
        self.actions = actions
    }

    func handle(frame points: [TouchPoint], timestamp: Double) {
        guard isEnabled else { return }

        var seen = Set<Int32>()
        for p in points where p.isDown {
            let pos = CGPoint(x: p.x, y: p.y)
            seen.insert(p.id)

            if var track = tracks[p.id] {
                track.last = pos
                tracks[p.id] = track
            } else {
                tracks[p.id] = Track(start: pos, startTime: timestamp, last: pos,
                                     control: DeckLayout.control(at: pos))
            }

            if let control = tracks[p.id]?.control, case .slider(let slider) = control.kind {
                let raw = 1 - (pos.y - control.rect.minY) / control.rect.height
                setSlider(slider, Double(min(max(raw, 0), 1)))
            }
        }

        // Fingers that lifted this frame.
        for (id, track) in tracks where !seen.contains(id) {
            tracks[id] = nil
            guard !track.consumed, case .key(let key)? = track.control?.kind else { continue }
            let moved = hypot(track.last.x - track.start.x, track.last.y - track.start.y)
            if timestamp - track.startTime < Self.tapMaxDuration, moved < Self.tapMaxDistance {
                fire(key)
            }
        }

        publish()
    }

    /// Physical click on the trackpad while the deck is up.
    func handleClick() {
        guard isEnabled else { return }
        // The most recently landed finger is the one doing the pointing.
        guard let latest = tracks.max(by: { $0.value.startTime < $1.value.startTime }) else { return }
        tracks[latest.key]?.consumed = true
        if case .key(let key)? = DeckLayout.control(at: latest.value.last)?.kind {
            fire(key)
        }
    }

    // MARK: - Private

    private func setSlider(_ slider: SliderID, _ value: Double) {
        let current = state.sliderValues[slider] ?? -1
        guard abs(current - value) > Self.sliderEpsilon else { return }
        state.sliderValues[slider] = value
        actions.setSlider(slider, value)
    }

    private func fire(_ key: DeckKey) {
        actions.press(key)
        state.flashKey = key
        let state = self.state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak state] in
            if state?.flashKey == key { state?.flashKey = nil }
        }
    }

    private func publish() {
        state.fingers = tracks
            .map { FingerDot(id: $0.key, point: $0.value.last) }
            .sorted { $0.id < $1.id }

        let hovered = Set(tracks.values.compactMap { track -> DeckKey? in
            if case .key(let key)? = DeckLayout.control(at: track.last)?.kind { return key }
            return nil
        })
        if hovered != state.hoveredKeys { state.hoveredKeys = hovered }
    }

    private func reset() {
        tracks.removeAll()
        state.fingers = []
        state.hoveredKeys = []
    }
}
