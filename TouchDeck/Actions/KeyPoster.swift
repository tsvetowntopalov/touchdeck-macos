import Carbon.HIToolbox
import CoreGraphics

/// Posts real keypad key events to whatever app is frontmost.
enum KeyPoster {
    /// Tag on our synthetic events so the EventTap can strip the held ⌃⌥ from them.
    static let marker: Int64 = 0x7D_EC_7D_EC

    static func post(_ key: DeckKey) {
        let (code, isKeypad) = keyCode(for: key)
        let source = CGEventSource(stateID: .privateState)

        for isDown in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: isDown) else { continue }
            event.flags = isKeypad ? .maskNumericPad : []
            event.setIntegerValueField(.eventSourceUserData, value: marker)
            event.post(tap: .cghidEventTap)
        }
    }

    private static func keyCode(for key: DeckKey) -> (CGKeyCode, Bool) {
        switch key {
        case .digit(let d):
            let codes = [
                kVK_ANSI_Keypad0, kVK_ANSI_Keypad1, kVK_ANSI_Keypad2, kVK_ANSI_Keypad3, kVK_ANSI_Keypad4,
                kVK_ANSI_Keypad5, kVK_ANSI_Keypad6, kVK_ANSI_Keypad7, kVK_ANSI_Keypad8, kVK_ANSI_Keypad9,
            ]
            return (CGKeyCode(codes[max(0, min(9, d))]), true)
        case .decimal: return (CGKeyCode(kVK_ANSI_KeypadDecimal), true)
        case .plus: return (CGKeyCode(kVK_ANSI_KeypadPlus), true)
        case .minus: return (CGKeyCode(kVK_ANSI_KeypadMinus), true)
        case .multiply: return (CGKeyCode(kVK_ANSI_KeypadMultiply), true)
        case .divide: return (CGKeyCode(kVK_ANSI_KeypadDivide), true)
        case .enter: return (CGKeyCode(kVK_ANSI_KeypadEnter), true)
        case .backspace: return (CGKeyCode(kVK_Delete), false)
        }
    }
}
