import CoreData
import Foundation

@objc(ExamOrder)
public final class ExamOrder: NSManagedObject, Identifiable {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
}

extension ExamOrder {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExamOrder> {
        NSFetchRequest<ExamOrder>(entityName: "ExamOrder")
    }

    @NSManaged public var examName: String
    @NSManaged public var examType: String
    @NSManaged public var indication: String?
    @NSManaged public var consultation: Consultation
}
