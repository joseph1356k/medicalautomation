import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "MiniPRM", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

private extension PersistenceController {
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "Patient"
        entity.managedObjectClassName = NSStringFromClass(Patient.self)

        let fullName = stringAttribute(name: "fullName", optional: false)
        let documentId = stringAttribute(name: "documentId", optional: false)
        let phone = stringAttribute(name: "phone", optional: false)
        let email = stringAttribute(name: "email", optional: false)
        let address = stringAttribute(name: "address", optional: false)
        let createdAt = dateAttribute(name: "createdAt", optional: false, defaultValue: Date())

        entity.properties = [fullName, documentId, phone, email, address, createdAt]
        model.entities = [entity]
        return model
    }

    static func stringAttribute(name: String, optional: Bool) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .stringAttributeType
        attribute.isOptional = optional
        attribute.defaultValue = ""
        return attribute
    }

    static func dateAttribute(name: String, optional: Bool, defaultValue: Date) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .dateAttributeType
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }
}
