import AppKit
import SwiftUI

@main
struct MiniPRMApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup("Pacientes") {
            PatientsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
