// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MiniPRM",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MiniPRM",
            path: ".",
            sources: [
                "MiniPRMApp.swift",
                "Patient+CoreDataClass.swift",
                "Patient+CoreDataProperties.swift",
                "PatientFormView.swift",
                "PatientsView.swift",
                "PersistenceController.swift"
            ]
        )
    ]
)
