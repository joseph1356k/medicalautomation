import SwiftUI

// MARK: - Enum para manejar un solo sheet

private enum ActiveSheet: Identifiable {
    case newPatient
    case consultation(Patient)
    case detail(Patient)

    var id: String {
        switch self {
        case .newPatient:              return "newPatient"
        case .consultation(let p):     return "consultation-\(p.objectID.uriRepresentation())"
        case .detail(let p):           return "detail-\(p.objectID.uriRepresentation())"
        }
    }
}

// MARK: - Vista principal

struct PatientsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Patient.createdAt, ascending: false)],
        animation: nil
    )
    private var patients: FetchedResults<Patient>

    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var activeSheet: ActiveSheet?

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
            // Buscador nativo SwiftUI (reemplaza NSViewRepresentable)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Buscar por nombre o documento", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(7)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
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
                            activeSheet = .consultation(patient)
                        } label: {
                            Label("Consultar", systemImage: "stethoscope")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button {
                            activeSheet = .detail(patient)
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
                    activeSheet = .newPatient
                }
            }
        }
        // Un solo sheet en lugar de tres separados
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .newPatient:
                PatientFormView()
                    .environment(\.managedObjectContext, viewContext)

            case .consultation(let patient):
                ConsultationView(patient: patient)
                    .environment(\.managedObjectContext, viewContext)

            case .detail(let patient):
                PatientDetailView(patient: patient)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}
