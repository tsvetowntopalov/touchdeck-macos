import CoreGraphics
import Foundation

/// Hides the mouse cursor while the deck is up.
///
/// `CGDisplayHideCursor` only works for the frontmost app, and TouchDeck never
/// takes focus. The private "SetsCursorInBackground" connection property lifts
/// that restriction (same trick used by cursor-hiding utilities like Cursorcerer).
enum CursorHider {
    private typealias DefaultConnectionFn = @convention(c) () -> Int32
    private typealias SetPropertyFn = @convention(c) (Int32, Int32, CFString, CFTypeRef) -> Int32

    private static let handle = dlopen(
        "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_NOW
    )

    private static let defaultConnection: DefaultConnectionFn? = handle
        .flatMap { dlsym($0, "_CGSDefaultConnection") }
        .map { unsafeBitCast($0, to: DefaultConnectionFn.self) }

    private static let setProperty: SetPropertyFn? = handle
        .flatMap { dlsym($0, "CGSSetConnectionProperty") }
        .map { unsafeBitCast($0, to: SetPropertyFn.self) }

    /// Set once; the property sticks for the life of the connection.
    private static let allowBackgroundCursor: Void = {
        guard let defaultConnection, let setProperty else { return }
        let cid = defaultConnection()
        _ = setProperty(cid, cid, "SetsCursorInBackground" as CFString, kCFBooleanTrue)
    }()

    /// Hide/show calls are reference-counted by the window server, so track our
    /// own state and never send two of the same in a row.
    private static var isHidden = false

    static func hide() {
        guard !isHidden else { return }
        _ = allowBackgroundCursor
        CGDisplayHideCursor(CGMainDisplayID())
        isHidden = true
    }

    static func show() {
        guard isHidden else { return }
        CGDisplayShowCursor(CGMainDisplayID())
        isHidden = false
    }
}
