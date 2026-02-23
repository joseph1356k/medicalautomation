import CoreData
import Foundation

// MARK: - Draft structs (estado temporal antes de guardar en CoreData)

struct PrescriptionDraft: Identifiable {
    let id = UUID()
    var medication = ""
    var dose = ""
    var frequency = ""
    var duration = ""
    var instructions = ""

    var isValid: Bool { !medication.trimmingCharacters(in: .whitespaces).isEmpty }
}

struct ExamOrderDraft: Identifiable {
    let id = UUID()
    var examName = ""
    var examType = ExamOrderType.laboratory
    var indication = ""

    var isValid: Bool { !examName.trimmingCharacters(in: .whitespaces).isEmpty }
}

enum ExamOrderType: String, CaseIterable {
    case laboratory = "Laboratorio"
    case imaging = "Imagen"
    case procedure = "Procedimiento"
    case other = "Otro"
}

// MARK: - Secciones de navegacion

enum ConsultationSection: String, CaseIterable, Identifiable {
    case vitalSigns = "Signos Vitales"
    case anamnesis = "Anamnesis"
    case physicalExam = "Examen Físico"
    case diagnosis = "Diagnóstico"
    case prescriptions = "Prescripciones"
    case examOrders = "Órdenes de Exámenes"
    case plan = "Plan y Próxima Cita"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .vitalSigns:    return "waveform.path.ecg"
        case .anamnesis:     return "text.alignleft"
        case .physicalExam:  return "stethoscope"
        case .diagnosis:     return "cross.case"
        case .prescriptions: return "pill"
        case .examOrders:    return "testtube.2"
        case .plan:          return "calendar.badge.plus"
        }
    }
}

// MARK: - Modelo del formulario

final class ConsultationFormModel: ObservableObject {

    // Metadatos
    @Published var date: Date = Date()
    @Published var reason: String = ""

    // Signos Vitales
    @Published var bloodPressure: String = ""
    @Published var heartRate: String = ""
    @Published var respiratoryRate: String = ""
    @Published var temperature: String = ""
    @Published var spo2: String = ""
    @Published var weight: String = ""
    @Published var height: String = ""

    var bmi: String {
        let w = Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 0
        let h = Double(height.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard w > 0, h > 0 else { return "" }
        let hm = h > 10 ? h / 100.0 : h
        return String(format: "%.1f", w / (hm * hm))
    }

    // Anamnesis
    @Published var currentIllness: String = ""
    @Published var pathologicalHistory: String = ""
    @Published var surgicalHistory: String = ""
    @Published var familyHistory: String = ""
    @Published var pharmacologicalHistory: String = ""
    @Published var allergyHistory: String = ""
    @Published var systemsReview: String = ""

    // Examen Fisico
    @Published var generalExam: String = ""
    @Published var cardiovascularExam: String = ""
    @Published var respiratoryExam: String = ""
    @Published var abdominalExam: String = ""
    @Published var neurologicalExam: String = ""
    @Published var otherExam: String = ""

    // Diagnostico
    @Published var diagnosis: String = ""
    @Published var secondaryDiagnoses: String = ""
    @Published var diagnosticNotes: String = ""

    // Prescripciones
    @Published var prescriptions: [PrescriptionDraft] = []
    @Published var isAddingPrescription = false
    @Published var newPrescription = PrescriptionDraft()

    // Ordenes
    @Published var examOrders: [ExamOrderDraft] = []
    @Published var isAddingExamOrder = false
    @Published var newExamOrder = ExamOrderDraft()

    // Plan y proxima cita
    @Published var managementPlan: String = ""
    @Published var recommendations: String = ""
    @Published var notes: String = ""
    @Published var scheduleNextAppointment: Bool = false
    @Published var nextAppointmentDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @Published var nextAppointmentReason: String = ""

    // Navegacion
    @Published var selectedSection: ConsultationSection = .vitalSigns

    var isValid: Bool {
        !reason.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Prescripciones

    func addPrescription() {
        guard newPrescription.isValid else { return }
        prescriptions.append(newPrescription)
        newPrescription = PrescriptionDraft()
        isAddingPrescription = false
    }

    func removePrescription(_ draft: PrescriptionDraft) {
        prescriptions.removeAll { $0.id == draft.id }
    }

    // MARK: - Examenes

    func addExamOrder() {
        guard newExamOrder.isValid else { return }
        examOrders.append(newExamOrder)
        newExamOrder = ExamOrderDraft()
        isAddingExamOrder = false
    }

    func removeExamOrder(_ draft: ExamOrderDraft) {
        examOrders.removeAll { $0.id == draft.id }
    }

    // MARK: - Persistencia

    func save(for patient: Patient, in context: NSManagedObjectContext) throws {
        let consultation = Consultation(context: context)
        consultation.date = date
        consultation.reason = reason.trimmingCharacters(in: .whitespaces)
        consultation.patient = patient

        consultation.bloodPressure = nilIfEmpty(bloodPressure)
        consultation.heartRate = nilIfEmpty(heartRate)
        consultation.respiratoryRate = nilIfEmpty(respiratoryRate)
        consultation.temperature = nilIfEmpty(temperature)
        consultation.spo2 = nilIfEmpty(spo2)
        consultation.weight = nilIfEmpty(weight)
        consultation.height = nilIfEmpty(height)
        consultation.bmi = nilIfEmpty(bmi)

        consultation.currentIllness = nilIfEmpty(currentIllness)
        consultation.pathologicalHistory = nilIfEmpty(pathologicalHistory)
        consultation.surgicalHistory = nilIfEmpty(surgicalHistory)
        consultation.familyHistory = nilIfEmpty(familyHistory)
        consultation.pharmacologicalHistory = nilIfEmpty(pharmacologicalHistory)
        consultation.allergyHistory = nilIfEmpty(allergyHistory)
        consultation.systemsReview = nilIfEmpty(systemsReview)

        consultation.generalExam = nilIfEmpty(generalExam)
        consultation.cardiovascularExam = nilIfEmpty(cardiovascularExam)
        consultation.respiratoryExam = nilIfEmpty(respiratoryExam)
        consultation.abdominalExam = nilIfEmpty(abdominalExam)
        consultation.neurologicalExam = nilIfEmpty(neurologicalExam)
        consultation.otherExam = nilIfEmpty(otherExam)

        consultation.diagnosis = nilIfEmpty(diagnosis)
        consultation.secondaryDiagnoses = nilIfEmpty(secondaryDiagnoses)
        consultation.diagnosticNotes = nilIfEmpty(diagnosticNotes)

        consultation.managementPlan = nilIfEmpty(managementPlan)
        consultation.recommendations = nilIfEmpty(recommendations)
        consultation.notes = nilIfEmpty(notes)

        for draft in prescriptions where draft.isValid {
            let p = Prescription(context: context)
            p.medication = draft.medication.trimmingCharacters(in: .whitespaces)
            p.dose = draft.dose.trimmingCharacters(in: .whitespaces)
            p.frequency = draft.frequency.trimmingCharacters(in: .whitespaces)
            p.duration = nilIfEmpty(draft.duration)
            p.instructions = nilIfEmpty(draft.instructions)
            p.consultation = consultation
        }

        for draft in examOrders where draft.isValid {
            let e = ExamOrder(context: context)
            e.examName = draft.examName.trimmingCharacters(in: .whitespaces)
            e.examType = draft.examType.rawValue
            e.indication = nilIfEmpty(draft.indication)
            e.consultation = consultation
        }

        if scheduleNextAppointment, !nextAppointmentReason.trimmingCharacters(in: .whitespaces).isEmpty {
            let appt = Appointment(context: context)
            appt.date = nextAppointmentDate
            appt.reason = nextAppointmentReason.trimmingCharacters(in: .whitespaces)
            appt.status = "Programada"
            appt.patient = patient
        }

        try context.save()
    }

    private func nilIfEmpty(_ s: String) -> String? {
        s.trimmingCharacters(in: .whitespaces).isEmpty ? nil : s.trimmingCharacters(in: .whitespaces)
    }
}
