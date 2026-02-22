import CoreData
import Foundation

extension Patient {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Patient> {
        NSFetchRequest<Patient>(entityName: "Patient")
    }

    @NSManaged public var fullName: String
    @NSManaged public var documentId: String
    @NSManaged public var phone: String
    @NSManaged public var email: String
    @NSManaged public var address: String
    @NSManaged public var createdAt: Date

    // Relaciones
    @NSManaged public var consultations: NSSet?
    @NSManaged public var appointments: NSSet?

    public var consultationsArray: [Consultation] {
        (consultations as? Set<Consultation> ?? []).sorted { $0.date > $1.date }
    }

    public var appointmentsArray: [Appointment] {
        (appointments as? Set<Appointment> ?? []).sorted { $0.date < $1.date }
    }

    public var upcomingAppointments: [Appointment] {
        appointmentsArray.filter { $0.date >= Date() && $0.status == "Programada" }
    }
}
