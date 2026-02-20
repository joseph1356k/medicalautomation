import SwiftUI

@main
struct MiniPRMApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup("Pacientes") {
            PatientsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
