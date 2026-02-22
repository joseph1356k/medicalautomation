import CoreData
import Foundation

@objc(Consultation)
public final class Consultation: NSManagedObject, Identifiable {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        date = Date()
    }
}

extension Consultation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Consultation> {
        NSFetchRequest<Consultation>(entityName: "Consultation")
    }

    // Metadatos
    @NSManaged public var date: Date
    @NSManaged public var reason: String

    // Signos Vitales
    @NSManaged public var bloodPressure: String?
    @NSManaged public var heartRate: String?
    @NSManaged public var respiratoryRate: String?
    @NSManaged public var temperature: String?
    @NSManaged public var spo2: String?
    @NSManaged public var weight: String?
    @NSManaged public var height: String?
    @NSManaged public var bmi: String?

    // Anamnesis
    @NSManaged public var currentIllness: String?
    @NSManaged public var pathologicalHistory: String?
    @NSManaged public var surgicalHistory: String?
    @NSManaged public var familyHistory: String?
    @NSManaged public var pharmacologicalHistory: String?
    @NSManaged public var allergyHistory: String?
    @NSManaged public var systemsReview: String?

    // Examen Fisico
    @NSManaged public var generalExam: String?
    @NSManaged public var cardiovascularExam: String?
    @NSManaged public var respiratoryExam: String?
    @NSManaged public var abdominalExam: String?
    @NSManaged public var neurologicalExam: String?
    @NSManaged public var otherExam: String?

    // Diagnostico
    @NSManaged public var diagnosis: String?
    @NSManaged public var secondaryDiagnoses: String?
    @NSManaged public var diagnosticNotes: String?

    // Plan
    @NSManaged public var managementPlan: String?
    @NSManaged public var recommendations: String?
    @NSManaged public var notes: String?

    // Relaciones
    @NSManaged public var patient: Patient
    @NSManaged public var prescriptions: NSSet?
    @NSManaged public var examOrders: NSSet?

    public var prescriptionsArray: [Prescription] {
        (prescriptions as? Set<Prescription> ?? []).sorted { $0.medication < $1.medication }
    }

    public var examOrdersArray: [ExamOrder] {
        (examOrders as? Set<ExamOrder> ?? []).sorted { $0.examName < $1.examName }
    }

    public var hasVitalSigns: Bool {
        [bloodPressure, heartRate, respiratoryRate, temperature, spo2, weight, height]
            .compactMap { $0 }.contains { !$0.isEmpty }
    }
}
