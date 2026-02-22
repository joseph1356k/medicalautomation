import CoreData
import Foundation

@objc(Prescription)
public final class Prescription: NSManagedObject, Identifiable {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
}

extension Prescription {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Prescription> {
        NSFetchRequest<Prescription>(entityName: "Prescription")
    }

    @NSManaged public var medication: String
    @NSManaged public var dose: String
    @NSManaged public var frequency: String
    @NSManaged public var duration: String?
    @NSManaged public var instructions: String?
    @NSManaged public var consultation: Consultation
}
