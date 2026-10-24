import AppKit
import CoreGraphics

/// Global CGEventTap that
///  1. watches the modifier keys to show/hide the deck (hold-to-activate),
///  2. freezes and swallows pointer events while the deck is up,
///  3. turns a physical trackpad click into "press the key under my finger",
///  4. strips the held activation modifiers from the keys TouchDeck itself posts.
///
/// Needs the Accessibility permission (an active, event-modifying tap).
final class EventTap {
    /// Called on the main thread when the deck should appear / disappear.
    var onActivationChanged: ((Bool) -> Void)?
    /// Called on a physical click while the deck is up.
    var onClick: (() -> Void)?

    /// Exact modifier combination to hold. Default: ⌃⌥ (Control + Option).
    var activationModifiers: CGEventFlags = [.maskControl, .maskAlternate]

    private(set) var isActive = false
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private static let watchedModifiers: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand, .maskShift]

    private static let pointerEvents: [CGEventType] = [
        .mouseMoved,
        .leftMouseDown, .leftMouseUp, .leftMouseDragged,
        .rightMouseDown, .rightMouseUp, .rightMouseDragged,
        .otherMouseDown, .otherMouseUp, .otherMouseDragged,
        .scrollWheel,
    ]

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }

        let types = Self.pointerEvents + [.flagsChanged, .keyDown, .keyUp]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("TouchDeck: could not create event tap (Accessibility not granted?)")
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.runLoopSource = source
        return true
    }

    func stop() {
        setActive(false)
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
        tap = nil
        runLoopSource = nil
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)

        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return pass

        case .flagsChanged:
            let held = event.flags.intersection(Self.watchedModifiers)
            setActive(held == activationModifiers)
            return pass

        case .keyDown, .keyUp:
            // Keys we posted ourselves: drop the ⌃⌥ the user is physically holding,
            // otherwise the target app would receive ⌃⌥7 instead of 7.
            if event.getIntegerValueField(.eventSourceUserData) == KeyPoster.marker {
                event.flags = event.flags.subtracting(Self.watchedModifiers)
            }
            return pass

        default:
            guard isActive else { return pass }
            if type == .leftMouseDown { onClick?() }
            return nil // swallow pointer events while the deck is up
        }
    }

    private func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        // Freeze and hide the cursor while the trackpad drives the deck.
        CGAssociateMouseAndMouseCursorPosition(active ? 0 : 1)
        if active { CursorHider.hide() } else { CursorHider.show() }
        onActivationChanged?(active)
    }
}

private let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<EventTap>.fromOpaque(userInfo).takeUnretainedValue()
    return tap.handle(type: type, event: event)
}
