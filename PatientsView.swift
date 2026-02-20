import AppKit
import SwiftUI

struct PatientsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Patient.createdAt, ascending: false)],
        animation: nil
    )
    private var patients: FetchedResults<Patient>

    @State private var searchText = ""
    @State private var isNewPatientSheetPresented = false

    private var filteredPatients: [Patient] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return Array(patients) }

        return patients.filter { patient in
            patient.fullName.localizedCaseInsensitiveContains(query) ||
            patient.documentId.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SearchField(text: $searchText, placeholder: "Buscar por nombre o documento")
                .frame(maxWidth: 420)
                .accessibilityIdentifier("patients.search")

            Table(filteredPatients) {
                TableColumn("Nombre") { patient in
                    Text(patient.fullName)
                }
                TableColumn("Documento") { patient in
                    Text(patient.documentId)
                }
                TableColumn("Telefono") { patient in
                    Text(patient.phone)
                }
            }
            .accessibilityIdentifier("patients.table")
        }
        .padding(16)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Nuevo Paciente") {
                    isNewPatientSheetPresented = true
                }
                .accessibilityIdentifier("patients.newButton")
            }
        }
        .sheet(isPresented: $isNewPatientSheetPresented) {
            PatientFormView()
        }
    }
}

private struct SearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField(frame: .zero)
        field.placeholderString = placeholder
        field.sendsSearchStringImmediately = true
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            text = field.stringValue
        }
    }
}
