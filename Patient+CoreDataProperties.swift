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
}
