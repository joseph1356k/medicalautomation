import CoreData
import Foundation

@objc(Patient)
public final class Patient: NSManagedObject, Identifiable {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
    }
}
