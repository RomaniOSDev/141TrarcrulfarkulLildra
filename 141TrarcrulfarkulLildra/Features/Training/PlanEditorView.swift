import SwiftUI

struct PlanEditorView: View {
    @EnvironmentObject private var fitness: FitnessData
    @Environment(\.dismiss) private var dismiss

    @State private var draft: EditableTrainingPlan
    private let isEditing: Bool

    init(plan: EditableTrainingPlan?) {
        if let plan {
            _draft = State(initialValue: plan)
            isEditing = true
        } else {
            _draft = State(initialValue: EditableTrainingPlan.newDraft(sport: .running))
            isEditing = false
        }
    }

    private var canSave: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Plan title")
                    .font(.headline)
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                TextField("Required", text: $draft.title)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(Color.appPrimary)

                Text("Description")
                    .font(.headline)
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                TextField("Optional notes", text: $draft.subtitle, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .foregroundStyle(Color.appPrimary)

                Text("Sport")
                    .font(.headline)
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Picker("Sport", selection: $draft.sport) {
                    ForEach(SportCategory.allCases) { sport in
                        Text(sport.displayTitle).tag(sport)
                    }
                }
                .pickerStyle(.segmented)

                Text("Session type")
                    .font(.headline)
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Picker("Session type", selection: $draft.activity) {
                    ForEach(ActivityKind.allCases, id: \.self) { kind in
                        Text(kind.editorTitle).tag(kind)
                    }
                }
                .pickerStyle(.wheel)
                .frame(minHeight: 120)

                Text("Targets tune the starting point for sliders and timers inside each activity.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Stepper("Target BPM: \(draft.baseHeartRateTarget)", value: $draft.baseHeartRateTarget, in: 90...190, step: 1)

                Stepper("Target cadence: \(draft.baseCadenceTarget)", value: $draft.baseCadenceTarget, in: 40...120, step: 1)

                Stepper("Order in list: \(draft.sortOrder)", value: $draft.sortOrder, in: 0...999, step: 1)

                Button {
                    fitness.upsertCustomTrainingPlan(draft)
                    dismiss()
                } label: {
                    Text("Save plan")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .appPrimaryButtonChrome(enabled: canSave)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
            .padding(20)
            .appChromePanel(style: .outlined, cornerRadius: 22)
            .padding(16)
        }
        .appMeshScreenBackground()
        .navigationTitle(isEditing ? "Edit plan" : "New plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}
