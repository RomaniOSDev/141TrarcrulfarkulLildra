import SwiftUI

struct ProgramDetailView: View {
    @EnvironmentObject private var fitness: FitnessData
    let program: TrainingProgramDefinition
    @Binding var path: [TrainingDestination]

    @State private var difficulty: SessionDifficulty = .medium
    @State private var showPlanEditor = false
    @State private var showCopyConfirm = false

    private var effectiveProgram: TrainingProgramDefinition {
        fitness.programDefinition(for: program.id) ?? program
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(effectiveProgram.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text(effectiveProgram.subtitle)
                        .foregroundStyle(Color.appTextSecondary)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appChromePanel(style: .elevated, cornerRadius: 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Difficulty")
                        .font(.headline)
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(SessionDifficulty.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appChromePanel(style: .inset, cornerRadius: 18)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Completion")
                        .font(.headline)
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    ProgressView(value: fitness.completionRatio(for: effectiveProgram.id))
                        .tint(Color.appAccent)
                    Text("Stars reflect finish quality, zone control, and personal progress.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appChromePanel(style: .inset, cornerRadius: 18)

                if !CustomTrainingPlanSupport.isCustomPlanId(program.id) {
                    Button {
                        _ = fitness.duplicateCatalogProgram(effectiveProgram)
                        showCopyConfirm = true
                    } label: {
                        Text("Save as my plan")
                            .font(.headline)
                            .foregroundStyle(Color.appPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                            .appSecondaryOutlineChrome()
                    }
                    .buttonStyle(.plain)
                }

                startButton
            }
            .padding(16)
        }
        .background(Color.clear)
        .navigationTitle("Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if CustomTrainingPlanSupport.isCustomPlanId(program.id) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showPlanEditor = true
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(minHeight: 44)
                }
            }
        }
        .sheet(isPresented: $showPlanEditor) {
            NavigationStack {
                if let editable = fitness.customTrainingPlans.first(where: { $0.id == program.id }) {
                    PlanEditorView(plan: editable)
                } else {
                    Text("Plan unavailable")
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(16)
                }
            }
            .environmentObject(fitness)
        }
        .alert("Plan saved", isPresented: $showCopyConfirm) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A copy was added under My plans. You can edit it anytime.")
        }
    }

    @ViewBuilder
    private var startButton: some View {
        Button {
            let destination: TrainingDestination
            switch effectiveProgram.activity {
            case .heartRateZone:
                destination = .heartSession(program: effectiveProgram, difficulty: difficulty)
            case .cadenceRhythm:
                destination = .cadenceSession(program: effectiveProgram, difficulty: difficulty)
            case .swimStreamline:
                destination = .swimSession(program: effectiveProgram, difficulty: difficulty)
            }
            path.append(destination)
        } label: {
            Text("Start session")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .appPrimaryButtonChrome(enabled: fitness.isUnlocked(programId: effectiveProgram.id))
        }
        .buttonStyle(.plain)
        .disabled(!fitness.isUnlocked(programId: effectiveProgram.id))
        .opacity(fitness.isUnlocked(programId: effectiveProgram.id) ? 1 : 0.4)
    }
}
