import CoreData
import SwiftUI

// MARK: - Vista principal

struct ConsultationView: View {
    let patient: Patient

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = ConsultationFormModel()
    @State private var alertMessage = ""
    @State private var isAlertPresented = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                sidebarNav
                Divider()
                contentArea
            }
        }
        .frame(width: 920, height: 700)
        .alert("No se pudo guardar", isPresented: $isAlertPresented) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button("Cancelar") { dismiss() }
            Spacer()
            VStack(spacing: 2) {
                Text("Nueva Consulta")
                    .font(.headline)
                Text(patient.fullName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Guardar Consulta") { save() }
                .buttonStyle(.borderedProminent)
                .disabled(!model.isValid)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    // MARK: Sidebar

    private var sidebarNav: some View {
        List(ConsultationSection.allCases, selection: $model.selectedSection) { section in
            Label(section.rawValue, systemImage: section.systemImage)
                .tag(section)
        }
        .listStyle(.sidebar)
        .frame(width: 200)
    }

    // MARK: Contenido

    private var contentArea: some View {
        ScrollView {
            Group {
                switch model.selectedSection {
                case .vitalSigns:    VitalSignsSection(model: model)
                case .anamnesis:     AnamnesisSection(model: model)
                case .physicalExam:  PhysicalExamSection(model: model)
                case .diagnosis:     DiagnosisSection(model: model)
                case .prescriptions: PrescriptionsSection(model: model)
                case .examOrders:    ExamOrdersSection(model: model)
                case .plan:          PlanSection(model: model)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    // MARK: Save

    private func save() {
        guard model.isValid else {
            alertMessage = "El motivo de consulta es obligatorio."
            isAlertPresented = true
            return
        }
        do {
            try model.save(for: patient, in: viewContext)
            dismiss()
        } catch {
            alertMessage = "No se pudo guardar la consulta: \(error.localizedDescription)"
            isAlertPresented = true
        }
    }
}

// MARK: - Seccion 1: Signos Vitales

private struct VitalSignsSection: View {
    @ObservedObject var model: ConsultationFormModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("Motivo de Consulta")
            TextField("Describa el motivo principal (ej. cefalea, control HTA...)", text: $model.reason)
                .textFieldStyle(.roundedBorder)

            Divider()

            SectionHeader("Signos Vitales")

            LazyVGrid(columns: columns, spacing: 16) {
                VitalField("Presión Arterial", hint: "120/80", text: $model.bloodPressure, unit: "mmHg")
                VitalField("Frecuencia Cardíaca", hint: "72", text: $model.heartRate, unit: "lpm")
                VitalField("Frec. Respiratoria", hint: "16", text: $model.respiratoryRate, unit: "rpm")
                VitalField("Temperatura", hint: "36.5", text: $model.temperature, unit: "°C")
                VitalField("SpO2", hint: "98", text: $model.spo2, unit: "%")
                VitalField("Peso", hint: "70", text: $model.weight, unit: "kg")
                VitalField("Talla", hint: "175", text: $model.height, unit: "cm")

                // IMC calculado
                VStack(alignment: .leading, spacing: 4) {
                    Text("IMC (calculado)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text(model.bmi.isEmpty ? "—" : model.bmi)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                        Text("kg/m²")
                            .foregroundStyle(.secondary)
                    }
                    if let label = bmiLabel(model.bmi) {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(bmiColor(model.bmi))
                    }
                }
            }
        }
    }

    private func bmiLabel(_ s: String) -> String? {
        guard let v = Double(s) else { return nil }
        switch v {
        case ..<18.5: return "Bajo peso"
        case 18.5..<25: return "Peso normal"
        case 25..<30: return "Sobrepeso"
        default: return "Obesidad"
        }
    }

    private func bmiColor(_ s: String) -> Color {
        guard let v = Double(s) else { return .secondary }
        switch v {
        case 18.5..<25: return .green
        case 25..<30: return .orange
        default: return .red
        }
    }
}

// MARK: - Seccion 2: Anamnesis

private struct AnamnesisSection: View {
    @ObservedObject var model: ConsultationFormModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MedTextEditor("Enfermedad Actual", text: $model.currentIllness, height: 100)

            Divider()
            SectionHeader("Antecedentes")

            MedTextEditor("Patológicos (HTA, DM, etc.)", text: $model.pathologicalHistory, height: 60)
            MedTextEditor("Quirúrgicos", text: $model.surgicalHistory, height: 60)
            MedTextEditor("Familiares", text: $model.familyHistory, height: 60)
            MedTextEditor("Farmacológicos (medicamentos actuales)", text: $model.pharmacologicalHistory, height: 60)
            MedTextEditor("Alérgicos", text: $model.allergyHistory, height: 60)

            Divider()
            MedTextEditor("Revisión por Sistemas", text: $model.systemsReview, height: 80)
        }
    }
}

// MARK: - Seccion 3: Examen Fisico

private struct PhysicalExamSection: View {
    @ObservedObject var model: ConsultationFormModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MedTextEditor("General", text: $model.generalExam, height: 70)
            MedTextEditor("Cardiovascular", text: $model.cardiovascularExam, height: 70)
            MedTextEditor("Respiratorio", text: $model.respiratoryExam, height: 70)
            MedTextEditor("Abdominal", text: $model.abdominalExam, height: 70)
            MedTextEditor("Neurológico", text: $model.neurologicalExam, height: 70)
            MedTextEditor("Otros hallazgos", text: $model.otherExam, height: 70)
        }
    }
}

// MARK: - Seccion 4: Diagnostico

private struct DiagnosisSection: View {
    @ObservedObject var model: ConsultationFormModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MedTextEditor("Diagnóstico Principal", text: $model.diagnosis, height: 70)
            MedTextEditor("Diagnósticos Secundarios", text: $model.secondaryDiagnoses, height: 70)
            MedTextEditor("Notas Diagnósticas", text: $model.diagnosticNotes, height: 70)
        }
    }
}

// MARK: - Seccion 5: Prescripciones

private struct PrescriptionsSection: View {
    @ObservedObject var model: ConsultationFormModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader("Prescripciones (\(model.prescriptions.count))")
                Spacer()
                if !model.isAddingPrescription {
                    Button {
                        model.isAddingPrescription = true
                    } label: {
                        Label("Agregar", systemImage: "plus")
                    }
                }
            }

            if model.prescriptions.isEmpty && !model.isAddingPrescription {
                emptyState("Sin medicamentos prescritos", icon: "pill")
            }

            ForEach(model.prescriptions) { draft in
                PrescriptionRow(draft: draft) {
                    model.removePrescription(draft)
                }
            }

            if model.isAddingPrescription {
                PrescriptionFormCard(
                    draft: $model.newPrescription,
                    onAdd: { model.addPrescription() },
                    onCancel: {
                        model.newPrescription = PrescriptionDraft()
                        model.isAddingPrescription = false
                    }
                )
            }
        }
    }
}

private struct PrescriptionRow: View {
    let draft: PrescriptionDraft
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "pill.fill")
                .foregroundStyle(.blue)
                .frame(width: 20)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(draft.medication)  \(draft.dose)")
                    .fontWeight(.medium)
                Text("\(draft.frequency)\(draft.duration.isEmpty ? "" : " · \(draft.duration)")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !draft.instructions.isEmpty {
                    Text(draft.instructions)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(role: .destructive) { onDelete() } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PrescriptionFormCard: View {
    @Binding var draft: PrescriptionDraft
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nuevo Medicamento")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                LabeledTextField("Medicamento *", hint: "ej. Amoxicilina", text: $draft.medication)
                LabeledTextField("Dosis *", hint: "ej. 500mg", text: $draft.dose)
            }
            HStack(spacing: 12) {
                LabeledTextField("Frecuencia *", hint: "ej. Cada 8 horas", text: $draft.frequency)
                LabeledTextField("Duración", hint: "ej. 7 días", text: $draft.duration)
            }
            LabeledTextField("Indicaciones especiales", hint: "ej. Tomar con alimentos", text: $draft.instructions)

            HStack {
                Spacer()
                Button("Cancelar", action: onCancel)
                Button("Agregar", action: onAdd)
                    .buttonStyle(.borderedProminent)
                    .disabled(!draft.isValid)
            }
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Seccion 6: Ordenes de Examenes

private struct ExamOrdersSection: View {
    @ObservedObject var model: ConsultationFormModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader("Órdenes de Exámenes (\(model.examOrders.count))")
                Spacer()
                if !model.isAddingExamOrder {
                    Button {
                        model.isAddingExamOrder = true
                    } label: {
                        Label("Agregar", systemImage: "plus")
                    }
                }
            }

            if model.examOrders.isEmpty && !model.isAddingExamOrder {
                emptyState("Sin órdenes de exámenes", icon: "testtube.2")
            }

            ForEach(model.examOrders) { draft in
                ExamOrderRow(draft: draft) {
                    model.removeExamOrder(draft)
                }
            }

            if model.isAddingExamOrder {
                ExamOrderFormCard(
                    draft: $model.newExamOrder,
                    onAdd: { model.addExamOrder() },
                    onCancel: {
                        model.newExamOrder = ExamOrderDraft()
                        model.isAddingExamOrder = false
                    }
                )
            }
        }
    }
}

private struct ExamOrderRow: View {
    let draft: ExamOrderDraft
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(draft.examType.rawValue)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(examTypeColor(draft.examType).opacity(0.15))
                .foregroundStyle(examTypeColor(draft.examType))
                .clipShape(Capsule())
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.examName).fontWeight(.medium)
                if !draft.indication.isEmpty {
                    Text(draft.indication).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(role: .destructive) { onDelete() } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func examTypeColor(_ type: ExamOrderType) -> Color {
        switch type {
        case .laboratory: return .blue
        case .imaging: return .purple
        case .procedure: return .orange
        case .other: return .gray
        }
    }
}

private struct ExamOrderFormCard: View {
    @Binding var draft: ExamOrderDraft
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nuevo Examen")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                LabeledTextField("Nombre del examen *", hint: "ej. Hemograma completo", text: $draft.examName)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tipo").font(.caption).foregroundStyle(.secondary)
                    Picker("Tipo", selection: $draft.examType) {
                        ForEach(ExamOrderType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            LabeledTextField("Indicación", hint: "ej. Control de hemoglobina glicosilada", text: $draft.indication)

            HStack {
                Spacer()
                Button("Cancelar", action: onCancel)
                Button("Agregar", action: onAdd)
                    .buttonStyle(.borderedProminent)
                    .disabled(!draft.isValid)
            }
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Seccion 7: Plan y Proxima Cita

private struct PlanSection: View {
    @ObservedObject var model: ConsultationFormModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MedTextEditor("Plan de Manejo", text: $model.managementPlan, height: 100)
            MedTextEditor("Recomendaciones Generales", text: $model.recommendations, height: 80)
            MedTextEditor("Notas Adicionales", text: $model.notes, height: 70)

            Divider()

            Toggle("Programar próxima cita", isOn: $model.scheduleNextAppointment)
                .font(.headline)

            if model.scheduleNextAppointment {
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker("Fecha y hora",
                               selection: $model.nextAppointmentDate,
                               in: Date()...,
                               displayedComponents: [.date, .hourAndMinute])
                    LabeledTextField(
                        "Motivo de la cita",
                        hint: "ej. Control de resultados",
                        text: $model.nextAppointmentReason
                    )
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Componentes reutilizables

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title).font(.headline)
    }
}

private struct VitalField: View {
    let label: String
    let hint: String
    @Binding var text: String
    let unit: String

    init(_ label: String, hint: String, text: Binding<String>, unit: String) {
        self.label = label
        self.hint = hint
        _text = text
        self.unit = unit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                TextField(hint, text: $text)
                    .textFieldStyle(.roundedBorder)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
    }
}

private struct LabeledTextField: View {
    let label: String
    let hint: String
    @Binding var text: String

    init(_ label: String, hint: String = "", text: Binding<String>) {
        self.label = label
        self.hint = hint
        _text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(hint, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct MedTextEditor: View {
    let label: String
    @Binding var text: String
    let height: CGFloat

    init(_ label: String, text: Binding<String>, height: CGFloat = 80) {
        self.label = label
        _text = text
        self.height = height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: height)
                .padding(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        }
    }
}

private func emptyState(_ message: String, icon: String) -> some View {
    HStack {
        Spacer()
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        Spacer()
    }
}
