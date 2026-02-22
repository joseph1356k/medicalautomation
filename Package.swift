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
                "Consultation+CoreData.swift",
                "Prescription+CoreData.swift",
                "ExamOrder+CoreData.swift",
                "Appointment+CoreData.swift",
                "PersistenceController.swift",
                "ConsultationFormModel.swift",
                "PatientsView.swift",
                "PatientFormView.swift",
                "ConsultationView.swift",
                "PatientDetailView.swift",
            ]
        )
    ]
)
