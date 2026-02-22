import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        // Usar variable local para evitar captura de self en struct (closure escapante)
        let c = NSPersistentContainer(name: "MiniPRM", managedObjectModel: model)
        container = c

        if inMemory {
            c.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        c.loadPersistentStores { description, error in
            if error != nil {
                // Schema cambió — eliminar store y recrear (desarrollo)
                if let url = description.url {
                    let fm = FileManager.default
                    let base = url.deletingPathExtension()
                    let ext = url.pathExtension
                    for suffix in ["", "-shm", "-wal"] {
                        try? fm.removeItem(at: base.appendingPathExtension("\(ext)\(suffix)"))
                    }
                }
                c.loadPersistentStores { _, retryError in
                    if let retryError {
                        fatalError("CoreData: no se pudo recuperar el store: \(retryError)")
                    }
                }
            }
        }

        c.viewContext.automaticallyMergesChangesFromParent = true
        c.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

// MARK: - Model builder
private extension PersistenceController {

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ── Entities ──────────────────────────────────────────────
        let patientEntity = makePatientEntity()
        let consultationEntity = makeConsultationEntity()
        let prescriptionEntity = makePrescriptionEntity()
        let examOrderEntity = makeExamOrderEntity()
        let appointmentEntity = makeAppointmentEntity()

        // ── Relaciones ────────────────────────────────────────────
        // Patient ↔ Consultation (one-to-many)
        let patientToConsultations = relationship(
            "consultations", destination: consultationEntity,
            toMany: true, deleteRule: .cascadeDeleteRule)
        let consultationToPatient = relationship(
            "patient", destination: patientEntity,
            toMany: false, deleteRule: .nullifyDeleteRule)
        patientToConsultations.inverseRelationship = consultationToPatient
        consultationToPatient.inverseRelationship = patientToConsultations

        // Patient ↔ Appointment (one-to-many)
        let patientToAppointments = relationship(
            "appointments", destination: appointmentEntity,
            toMany: true, deleteRule: .cascadeDeleteRule)
        let appointmentToPatient = relationship(
            "patient", destination: patientEntity,
            toMany: false, deleteRule: .nullifyDeleteRule)
        patientToAppointments.inverseRelationship = appointmentToPatient
        appointmentToPatient.inverseRelationship = patientToAppointments

        // Consultation ↔ Prescription (one-to-many)
        let consultationToPrescriptions = relationship(
            "prescriptions", destination: prescriptionEntity,
            toMany: true, deleteRule: .cascadeDeleteRule)
        let prescriptionToConsultation = relationship(
            "consultation", destination: consultationEntity,
            toMany: false, deleteRule: .nullifyDeleteRule)
        consultationToPrescriptions.inverseRelationship = prescriptionToConsultation
        prescriptionToConsultation.inverseRelationship = consultationToPrescriptions

        // Consultation ↔ ExamOrder (one-to-many)
        let consultationToExamOrders = relationship(
            "examOrders", destination: examOrderEntity,
            toMany: true, deleteRule: .cascadeDeleteRule)
        let examOrderToConsultation = relationship(
            "consultation", destination: consultationEntity,
            toMany: false, deleteRule: .nullifyDeleteRule)
        consultationToExamOrders.inverseRelationship = examOrderToConsultation
        examOrderToConsultation.inverseRelationship = consultationToExamOrders

        // ── Asignar relaciones a entities ─────────────────────────
        patientEntity.properties += [patientToConsultations, patientToAppointments]
        consultationEntity.properties += [consultationToPatient, consultationToPrescriptions, consultationToExamOrders]
        prescriptionEntity.properties += [prescriptionToConsultation]
        examOrderEntity.properties += [examOrderToConsultation]
        appointmentEntity.properties += [appointmentToPatient]

        model.entities = [patientEntity, consultationEntity, prescriptionEntity,
                          examOrderEntity, appointmentEntity]
        return model
    }

    // MARK: Entity builders

    static func makePatientEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "Patient"
        e.managedObjectClassName = NSStringFromClass(Patient.self)
        e.properties = [
            str("fullName"),
            str("documentId"),
            str("phone"),
            str("email"),
            str("address"),
            date("createdAt", defaultValue: Date()),
        ]
        return e
    }

    static func makeConsultationEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "Consultation"
        e.managedObjectClassName = NSStringFromClass(Consultation.self)
        e.properties = [
            date("date", defaultValue: Date()),
            str("reason"),
            // Vitales
            optStr("bloodPressure"), optStr("heartRate"), optStr("respiratoryRate"),
            optStr("temperature"), optStr("spo2"), optStr("weight"),
            optStr("height"), optStr("bmi"),
            // Anamnesis
            optStr("currentIllness"), optStr("pathologicalHistory"), optStr("surgicalHistory"),
            optStr("familyHistory"), optStr("pharmacologicalHistory"), optStr("allergyHistory"),
            optStr("systemsReview"),
            // Examen fisico
            optStr("generalExam"), optStr("cardiovascularExam"), optStr("respiratoryExam"),
            optStr("abdominalExam"), optStr("neurologicalExam"), optStr("otherExam"),
            // Diagnostico
            optStr("diagnosis"), optStr("secondaryDiagnoses"), optStr("diagnosticNotes"),
            // Plan
            optStr("managementPlan"), optStr("recommendations"), optStr("notes"),
        ]
        return e
    }

    static func makePrescriptionEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "Prescription"
        e.managedObjectClassName = NSStringFromClass(Prescription.self)
        e.properties = [
            str("medication"), str("dose"), str("frequency"),
            optStr("duration"), optStr("instructions"),
        ]
        return e
    }

    static func makeExamOrderEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "ExamOrder"
        e.managedObjectClassName = NSStringFromClass(ExamOrder.self)
        e.properties = [
            str("examName"), str("examType"),
            optStr("indication"),
        ]
        return e
    }

    static func makeAppointmentEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "Appointment"
        e.managedObjectClassName = NSStringFromClass(Appointment.self)
        e.properties = [
            date("date", defaultValue: Date()),
            str("reason"), str("status"),
            optStr("notes"),
        ]
        return e
    }

    // MARK: Attribute helpers

    static func str(_ name: String) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .stringAttributeType
        a.isOptional = false
        a.defaultValue = ""
        return a
    }

    static func optStr(_ name: String) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .stringAttributeType
        a.isOptional = true
        return a
    }

    static func date(_ name: String, defaultValue: Date) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .dateAttributeType
        a.isOptional = false
        a.defaultValue = defaultValue
        return a
    }

    static func relationship(
        _ name: String,
        destination: NSEntityDescription,
        toMany: Bool,
        deleteRule: NSDeleteRule
    ) -> NSRelationshipDescription {
        let r = NSRelationshipDescription()
        r.name = name
        r.destinationEntity = destination
        r.minCount = 0
        r.maxCount = toMany ? 0 : 1
        r.isOptional = true
        r.deleteRule = deleteRule
        return r
    }
}
