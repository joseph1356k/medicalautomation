import CoreData
import SwiftUI

// MARK: - Vista de historial del paciente

struct PatientDetailView: View {
    let patient: Patient

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConsultation: Consultation?
    @State private var isNewConsultationPresented = false

    var body: some View {
        VStack(spacing: 0) {
            patientHeader
            Divider()
            HStack(spacing: 0) {
                leftPanel
                    .frame(width: 280)
                Divider()
                rightPanel
            }
        }
        .frame(minWidth: 820, minHeight: 560)
        .sheet(isPresented: $isNewConsultationPresented) {
            ConsultationView(patient: patient)
                .environment(\.managedObjectContext, viewContext)
                .onDisappear {
                    // Refrescar la seleccion si hay una nueva consulta
                    if selectedConsultation == nil {
                        selectedConsultation = patient.consultationsArray.first
                    }
                }
        }
    }

    // MARK: Header

    private var patientHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName)
                    .font(.title2)
                    .fontWeight(.semibold)
                HStack(spacing: 16) {
                    Label(patient.documentId, systemImage: "person.text.rectangle")
                    if !patient.phone.isEmpty {
                        Label(patient.phone, systemImage: "phone")
                    }
                    if !patient.email.isEmpty {
                        Label(patient.email, systemImage: "envelope")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button("Cerrar") { dismiss() }
                Button {
                    isNewConsultationPresented = true
                } label: {
                    Label("Nueva Consulta", systemImage: "stethoscope")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }

    // MARK: Panel izquierdo

    private var leftPanel: some View {
        List(selection: $selectedConsultation) {
            if patient.consultationsArray.isEmpty && patient.upcomingAppointments.isEmpty {
                Text("Sin historial médico")
                    .foregroundStyle(.secondary)
                    .padding()
            }

            if !patient.consultationsArray.isEmpty {
                Section("Consultas (\(patient.consultationsArray.count))") {
                    ForEach(patient.consultationsArray) { consultation in
                        ConsultationListRow(consultation: consultation)
                            .tag(consultation)
                    }
                }
            }

            if !patient.upcomingAppointments.isEmpty {
                Section("Próximas Citas") {
                    ForEach(patient.upcomingAppointments) { appointment in
                        AppointmentListRow(appointment: appointment)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: Panel derecho

    @ViewBuilder
    private var rightPanel: some View {
        if let consultation = selectedConsultation {
            ConsultationDetailView(consultation: consultation)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("Selecciona una consulta")
                    .font(.title3)
                    .fontWeight(.medium)
                Text("Elige una consulta del historial para ver los detalles")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Fila de consulta en la lista

private struct ConsultationListRow: View {
    let consultation: Consultation

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(consultation.date.formatted(.dateTime.day().month(.abbreviated).year()))
                .font(.callout)
                .fontWeight(.medium)
            Text(consultation.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if !consultation.prescriptionsArray.isEmpty || !consultation.examOrdersArray.isEmpty {
                HStack(spacing: 6) {
                    if !consultation.prescriptionsArray.isEmpty {
                        Badge(text: "\(consultation.prescriptionsArray.count) Rx", color: .blue)
                    }
                    if !consultation.examOrdersArray.isEmpty {
                        Badge(text: "\(consultation.examOrdersArray.count) Ex", color: .orange)
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
}

private struct AppointmentListRow: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(appointment.date.formatted(.dateTime.day().month(.abbreviated).year()))
                .font(.callout)
                .fontWeight(.medium)
            Text(appointment.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(appointment.status)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Vista de detalle de una consulta

private struct ConsultationDetailView: View {
    let consultation: Consultation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Encabezado
                VStack(alignment: .leading, spacing: 4) {
                    Text(consultation.date.formatted(.dateTime.day().month(.wide).year()))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(consultation.reason)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                // Signos vitales
                if consultation.hasVitalSigns {
                    DetailCard(title: "Signos Vitales", icon: "waveform.path.ecg") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                           GridItem(.flexible()), GridItem(.flexible())],
                                  spacing: 12) {
                            VitalCell("PA", consultation.bloodPressure, "mmHg")
                            VitalCell("FC", consultation.heartRate, "lpm")
                            VitalCell("FR", consultation.respiratoryRate, "rpm")
                            VitalCell("Temp", consultation.temperature, "°C")
                            VitalCell("SpO2", consultation.spo2, "%")
                            VitalCell("Peso", consultation.weight, "kg")
                            VitalCell("Talla", consultation.height, "cm")
                            VitalCell("IMC", consultation.bmi, "kg/m²")
                        }
                    }
                }

                // Anamnesis
                if let illness = consultation.currentIllness, !illness.isEmpty {
                    DetailCard(title: "Enfermedad Actual", icon: "text.alignleft") {
                        Text(illness)
                    }
                }

                // Antecedentes relevantes
                let antecedents = [
                    ("Patológicos", consultation.pathologicalHistory),
                    ("Quirúrgicos", consultation.surgicalHistory),
                    ("Farmacológicos", consultation.pharmacologicalHistory),
                    ("Alérgicos", consultation.allergyHistory),
                ].compactMap { label, val -> (String, String)? in
                    guard let v = val, !v.isEmpty else { return nil }
                    return (label, v)
                }
                if !antecedents.isEmpty {
                    DetailCard(title: "Antecedentes", icon: "person.text.rectangle") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(antecedents, id: \.0) { label, value in
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(label).font(.caption).foregroundStyle(.secondary)
                                    Text(value).font(.body)
                                }
                            }
                        }
                    }
                }

                // Diagnostico
                if let dx = consultation.diagnosis, !dx.isEmpty {
                    DetailCard(title: "Diagnóstico", icon: "cross.case") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(dx).fontWeight(.medium)
                            if let secondary = consultation.secondaryDiagnoses, !secondary.isEmpty {
                                Text("Secundarios: \(secondary)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let notes = consultation.diagnosticNotes, !notes.isEmpty {
                                Text(notes).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Prescripciones
                if !consultation.prescriptionsArray.isEmpty {
                    DetailCard(title: "Prescripciones (\(consultation.prescriptionsArray.count))", icon: "pill") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(consultation.prescriptionsArray) { rx in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "pill.fill").foregroundStyle(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(rx.medication)  \(rx.dose)").fontWeight(.medium)
                                        Group {
                                            Text(rx.frequency) +
                                            Text(rx.duration.map { " · \($0)" } ?? "")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        if let inst = rx.instructions, !inst.isEmpty {
                                            Text(inst).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Examenes
                if !consultation.examOrdersArray.isEmpty {
                    DetailCard(title: "Órdenes (\(consultation.examOrdersArray.count))", icon: "testtube.2") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(consultation.examOrdersArray) { order in
                                HStack(spacing: 8) {
                                    Text(order.examType)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundStyle(.orange)
                                        .clipShape(Capsule())
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(order.examName).fontWeight(.medium)
                                        if let ind = order.indication, !ind.isEmpty {
                                            Text(ind).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Plan
                if let plan = consultation.managementPlan, !plan.isEmpty {
                    DetailCard(title: "Plan de Manejo", icon: "list.bullet.clipboard") {
                        Text(plan)
                    }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Componentes de detalle

private struct DetailCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct VitalCell: View {
    let label: String
    let value: String?
    let unit: String

    init(_ label: String, _ value: String?, _ unit: String) {
        self.label = label
        self.value = value
        self.unit = unit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            if let v = value, !v.isEmpty {
                HStack(spacing: 2) {
                    Text(v).fontWeight(.medium)
                    Text(unit).font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }
    }
}

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
