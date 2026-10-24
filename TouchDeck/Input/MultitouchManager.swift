import CoreGraphics
import Foundation

/// One finger on the trackpad, already converted to deck coordinates.
struct TouchPoint {
    /// Stable id for as long as the finger stays down.
    let id: Int32
    /// 0 = left edge, 1 = right edge.
    let x: CGFloat
    /// 0 = top edge, 1 = bottom edge (flipped from the trackpad's bottom-left origin).
    let y: CGFloat
    /// Raw `MTTouchState` value.
    let stage: Int32
    let pressure: Float

    /// True while the finger is actually in contact (makeTouch / touching).
    var isDown: Bool {
        stage == Int32(MTTouchStateMakeTouch.rawValue) || stage == Int32(MTTouchStateTouching.rawValue)
    }
}

/// Reads raw finger positions from every trackpad via the private
/// MultitouchSupport framework. Works globally, regardless of which app is focused.
final class MultitouchManager {
    static let shared = MultitouchManager()

    /// Delivered on the main queue for every frame (~90–120 Hz while touched).
    var onFrame: (([TouchPoint], Double) -> Void)?

    private(set) var isRunning = false

    private typealias CreateListFn = @convention(c) () -> Unmanaged<CFArray>?
    private typealias RegisterFn = @convention(c) (MTDeviceRef?, MTFrameCallbackFunction?) -> Void
    private typealias StartFn = @convention(c) (MTDeviceRef?, Int32) -> Void
    private typealias StopFn = @convention(c) (MTDeviceRef?) -> Void

    private static let frameworkPath =
        "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"

    /// Kept alive so the device objects it owns are never freed.
    private var deviceList: CFArray?
    private var devices: [MTDeviceRef] = []
    private var stopDevice: StopFn?

    /// C callback. Must not capture context, so it routes through `shared`.
    private static let frameCallback: MTFrameCallbackFunction = { _, touches, count, timestamp, _ in
        var points: [TouchPoint] = []
        if let touches, count > 0 {
            points.reserveCapacity(Int(count))
            for i in 0..<Int(count) {
                let t = touches[i]
                points.append(TouchPoint(
                    id: t.pathIndex,
                    x: CGFloat(t.normalizedVector.position.x),
                    y: CGFloat(1 - t.normalizedVector.position.y),
                    stage: t.stage,
                    pressure: t.zTotal
                ))
            }
        }
        DispatchQueue.main.async {
            MultitouchManager.shared.onFrame?(points, timestamp)
        }
    }

    @discardableResult
    func start() -> Bool {
        guard !isRunning else { return true }

        guard let handle = dlopen(Self.frameworkPath, RTLD_NOW) else {
            NSLog("TouchDeck: could not load MultitouchSupport.framework")
            return false
        }
        guard
            let createListSym = dlsym(handle, "MTDeviceCreateList"),
            let registerSym = dlsym(handle, "MTRegisterContactFrameCallback"),
            let startSym = dlsym(handle, "MTDeviceStart"),
            let stopSym = dlsym(handle, "MTDeviceStop")
        else {
            NSLog("TouchDeck: MultitouchSupport symbols missing")
            return false
        }

        let createList = unsafeBitCast(createListSym, to: CreateListFn.self)
        let register = unsafeBitCast(registerSym, to: RegisterFn.self)
        let startDevice = unsafeBitCast(startSym, to: StartFn.self)
        stopDevice = unsafeBitCast(stopSym, to: StopFn.self)

        guard let list = createList()?.takeRetainedValue() else { return false }
        deviceList = list

        for i in 0..<CFArrayGetCount(list) {
            guard let raw = CFArrayGetValueAtIndex(list, i) else { continue }
            let device = UnsafeMutableRawPointer(mutating: raw)
            register(device, Self.frameCallback)
            startDevice(device, 0)
            devices.append(device)
        }

        isRunning = !devices.isEmpty
        NSLog("TouchDeck: listening to \(devices.count) multitouch device(s)")
        return isRunning
    }

    func stop() {
        guard isRunning else { return }
        devices.forEach { stopDevice?($0) }
        devices.removeAll()
        deviceList = nil
        isRunning = false
    }
}
