import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = AppController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.start()
    }
}

@main
struct TouchDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("TouchDeck", systemImage: "hand.tap.fill") {
            MenuContent(controller: appDelegate.controller)
        }
    }
}

private struct MenuContent: View {
    @ObservedObject var controller: AppController

    var body: some View {
        Text("Hold ⌃⌥ to show the deck")
        Divider()
        Text(controller.hasAccessibility ? "✓ Accessibility granted" : "✗ Accessibility needed")
        if !controller.hasAccessibility {
            Button("Open Accessibility Settings…") { controller.openAccessibilitySettings() }
        }
        Text(controller.tapRunning ? "✓ Hotkey active" : "✗ Hotkey inactive")
        Text(controller.trackpadFound ? "✓ Trackpad connected" : "✗ No trackpad found")
        Divider()
        Button("Quit TouchDeck") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
