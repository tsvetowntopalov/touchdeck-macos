import AppKit
import ApplicationServices

/// Wires everything together: trackpad → router → state/actions, hotkey → panel.
final class AppController: ObservableObject {
    let state = DeckState()

    @Published private(set) var hasAccessibility = false
    @Published private(set) var tapRunning = false
    @Published private(set) var trackpadFound = false

    private let tap = EventTap()
    private let actions = DeckActions()
    private lazy var router = TouchRouter(state: state, actions: actions)
    private lazy var panel = OverlayPanel(state: state)
    private var permissionTimer: Timer?

    func start() {
        MultitouchManager.shared.onFrame = { [weak self] points, timestamp in
            self?.router.handle(frame: points, timestamp: timestamp)
        }
        trackpadFound = MultitouchManager.shared.start()

        tap.onActivationChanged = { [weak self] active in self?.setDeckVisible(active) }
        tap.onClick = { [weak self] in self?.router.handleClick() }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        hasAccessibility = AXIsProcessTrustedWithOptions(options)
        startTapWhenAllowed()
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Accessibility is often granted after launch, so poll until the tap can be created.
    private func startTapWhenAllowed() {
        if tryStartTap() { return }
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if self.tryStartTap() { timer.invalidate() }
        }
    }

    private func tryStartTap() -> Bool {
        hasAccessibility = AXIsProcessTrusted()
        guard hasAccessibility else { return false }
        tapRunning = tap.start()
        return tapRunning
    }

    private func setDeckVisible(_ visible: Bool) {
        router.isEnabled = visible
        state.isVisible = visible
        if visible {
            for (slider, value) in actions.readSliders() { state.sliderValues[slider] = value }
            panel.show()
        } else {
            panel.hide()
        }
    }
}
