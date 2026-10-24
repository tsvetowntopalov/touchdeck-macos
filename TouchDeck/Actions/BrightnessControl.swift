import CoreGraphics
import Foundation

/// Built-in display brightness via the private DisplayServices framework
/// (same API the brightness keys use). External monitors need DDC/CI instead —
/// see MonitorControl / BetterDisplay for that.
enum BrightnessControl {
    private typealias GetFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetFn = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private static let handle = dlopen(
        "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW
    )

    private static let getFn: GetFn? = handle
        .flatMap { dlsym($0, "DisplayServicesGetBrightness") }
        .map { unsafeBitCast($0, to: GetFn.self) }

    private static let setFn: SetFn? = handle
        .flatMap { dlsym($0, "DisplayServicesSetBrightness") }
        .map { unsafeBitCast($0, to: SetFn.self) }

    /// Prefer the built-in panel; fall back to the main display.
    private static var targetDisplay: CGDirectDisplayID {
        var count: UInt32 = 0
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        if CGGetOnlineDisplayList(UInt32(ids.count), &ids, &count) == .success {
            if let builtin = ids.prefix(Int(count)).first(where: { CGDisplayIsBuiltin($0) != 0 }) {
                return builtin
            }
        }
        return CGMainDisplayID()
    }

    static func get() -> Float? {
        guard let fn = getFn else { return nil }
        var value: Float = 0
        return fn(targetDisplay, &value) == 0 ? value : nil
    }

    static func set(_ value: Float) {
        guard let fn = setFn else { return }
        _ = fn(targetDisplay, max(0, min(1, value)))
    }
}
