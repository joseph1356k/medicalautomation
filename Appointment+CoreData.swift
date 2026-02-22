import CoreData
import Foundation

@objc(Appointment)
public final class Appointment: NSManagedObject, Identifiable {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        date = Date()
        status = "Programada"
    }
}

extension Appointment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Appointment> {
        NSFetchRequest<Appointment>(entityName: "Appointment")
    }

    @NSManaged public var date: Date
    @NSManaged public var reason: String
    @NSManaged public var status: String
    @NSManaged public var notes: String?
    @NSManaged public var patient: Patient
}
