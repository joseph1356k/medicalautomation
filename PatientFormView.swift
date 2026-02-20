import CoreData
import SwiftUI

struct PatientFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var documentId = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""

    @State private var isAlertPresented = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            Form {
                TextField("Nombre completo", text: $fullName)
                    .accessibilityIdentifier("patient.fullName")
                TextField("Documento", text: $documentId)
                    .accessibilityIdentifier("patient.documentId")
                TextField("Telefono", text: $phone)
                    .accessibilityIdentifier("patient.phone")
                TextField("Email", text: $email)
                    .accessibilityIdentifier("patient.email")
                TextField("Direccion", text: $address)
                    .accessibilityIdentifier("patient.address")
            }

            HStack {
                Spacer()
                Button("Cancelar") {
                    dismiss()
                }
                .accessibilityIdentifier("patient.cancelButton")

                Button("Guardar") {
                    savePatient()
                }
                .accessibilityIdentifier("patient.saveButton")
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(minWidth: 520, minHeight: 320)
        .alert("Error", isPresented: $isAlertPresented) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
}

private extension PatientFormView {
    func savePatient() {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDocument = documentId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedDocument.isEmpty else {
            alertMessage = "Nombre y Documento son obligatorios."
            isAlertPresented = true
            return
        }

        guard !documentExists(trimmedDocument) else {
            alertMessage = "Documento ya existe"
            isAlertPresented = true
            return
        }

        let patient = Patient(context: viewContext)
        patient.fullName = trimmedName
        patient.documentId = trimmedDocument
        patient.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.createdAt = Date()

        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "No se pudo guardar el paciente."
            isAlertPresented = true
        }
    }

    func documentExists(_ document: String) -> Bool {
        let request = Patient.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "documentId == %@", document)

        do {
            return try viewContext.count(for: request) > 0
        } catch {
            return false
        }
    }
}
