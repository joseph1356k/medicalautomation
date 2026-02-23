import AppKit
import SwiftUI

struct PatientsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Patient.createdAt, ascending: false)],
        animation: nil
    )
    private var patients: FetchedResults<Patient>

    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var selectedPatient: Patient?
    @State private var isNewPatientSheetPresented = false
    @State private var isDetailPresented = false
    @State private var isNewConsultationPresented = false

    private var filteredPatients: [Patient] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return Array(patients) }
        return patients.filter {
            $0.fullName.localizedCaseInsensitiveContains(query) ||
            $0.documentId.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SearchField(text: $searchText, placeholder: "Buscar por nombre o documento")
                .frame(maxWidth: 420)

            Table(filteredPatients) {
                TableColumn("Nombre") { (patient: Patient) in
                    Text(patient.fullName)
                }
                .width(min: 160, ideal: 200)

                TableColumn("Documento") { (patient: Patient) in
                    Text(patient.documentId)
                }
                .width(min: 100, ideal: 120)

                TableColumn("Teléfono") { (patient: Patient) in
                    Text(patient.phone)
                }
                .width(min: 100, ideal: 130)

                TableColumn("Consultas") { (patient: Patient) in
                    let count = patient.consultationsArray.count
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    } else {
                        Text("—").foregroundStyle(.secondary)
                    }
                }
                .width(min: 70, ideal: 80, max: 90)

                TableColumn("Acciones") { (patient: Patient) in
                    HStack(spacing: 6) {
                        Button {
                            selectedPatient = patient
                            isNewConsultationPresented = true
                        } label: {
                            Label("Consultar", systemImage: "stethoscope")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button {
                            selectedPatient = patient
                            isDetailPresented = true
                        } label: {
                            Label("Historial", systemImage: "list.bullet.clipboard")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .width(min: 200, ideal: 220)
            }
        }
        .padding(16)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Nuevo Paciente") {
                    isNewPatientSheetPresented = true
                }
            }
        }
        .sheet(isPresented: $isNewPatientSheetPresented) {
            PatientFormView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $isDetailPresented) {
            if let patient = selectedPatient {
                PatientDetailView(patient: patient)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $isNewConsultationPresented) {
            if let patient = selectedPatient {
                ConsultationView(patient: patient)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

// MARK: - NSSearchField wrapper

private struct SearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField(frame: .zero)
        field.placeholderString = placeholder
        field.sendsSearchStringImmediately = true
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        if nsView.stringValue != text { nsView.stringValue = text }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding private var text: String
        init(text: Binding<String>) { _text = text }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            text = field.stringValue
        }
    }
}
