import Foundation

/// What each control actually does to the system. Swap these out freely.
final class DeckActions {
    /// Current system values, read when the deck opens so sliders start in the right place.
    func readSliders() -> [SliderID: Double] {
        var values: [SliderID: Double] = [:]
        if let brightness = BrightnessControl.get() { values[.brightness] = Double(brightness) }
        if let volume = VolumeControl.get() { values[.volume] = Double(volume) }
        return values
    }

    func setSlider(_ slider: SliderID, _ value: Double) {
        switch slider {
        case .brightness:
            BrightnessControl.set(Float(value))
        case .volume:
            VolumeControl.set(Float(value))
        case .custom:
            // TODO: wire to anything — keyboard backlight, XDR boost, app-specific value, an n8n webhook…
            break
        }
    }

    func press(_ key: DeckKey) {
        KeyPoster.post(key)
    }
}
