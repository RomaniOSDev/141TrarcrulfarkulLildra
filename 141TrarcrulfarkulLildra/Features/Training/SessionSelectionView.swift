import SwiftUI

private enum SportScope: String, CaseIterable, Identifiable {
    case all
    case running
    case cycling
    case swimming

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All sports"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        }
    }

    var categories: [SportCategory] {
        switch self {
        case .all: return SportCategory.allCases
        case .running: return [.running]
        case .cycling: return [.cycling]
        case .swimming: return [.swimming]
        }
    }
}

private enum ActivityScope: String, CaseIterable, Identifiable {
    case all
    case heart
    case cadence
    case swim

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All types"
        case .heart: return "Heart rate"
        case .cadence: return "Cadence"
        case .swim: return "Swim"
        }
    }

    var kind: ActivityKind? {
        switch self {
        case .all: return nil
        case .heart: return .heartRateZone
        case .cadence: return .cadenceRhythm
        case .swim: return .swimStreamline
        }
    }
}

struct SessionSelectionView: View {
    @EnvironmentObject private var fitness: FitnessData
    @Binding var path: [TrainingDestination]

    @State private var showPlanManager = false
    @State private var searchText = ""
    @State private var sportScope: SportScope = .all
    @State private var activityScope: ActivityScope = .all
    @State private var favoriteLimitAlert = false

    var body: some View {
        List {
            Section {
                TextField("Search plans", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(Color.appPrimary)
                    .listRowBackground(Color.clear)

                Picker("Sport scope", selection: $sportScope) {
                    ForEach(SportScope.allCases) { scope in
                        Text(scope.label).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                Picker("Activity scope", selection: $activityScope) {
                    ForEach(ActivityScope.allCases) { scope in
                        Text(scope.label).tag(scope)
                    }
                }
                .pickerStyle(.menu)
                .listRowBackground(Color.clear)
            }

            ForEach(sportScope.categories) { sport in
                let rows = filteredPrograms(for: sport)
                if !rows.isEmpty {
                    Section {
                        ForEach(rows) { program in
                            NavigationLink(value: TrainingDestination.programDetail(program)) {
                                ProgramRow(program: program) { result in
                                    if result == .limitReached {
                                        favoriteLimitAlert = true
                                    }
                                }
                            }
                            .disabled(!fitness.isUnlocked(programId: program.id))
                            .opacity(fitness.isUnlocked(programId: program.id) ? 1 : 0.45)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(
                                AppPanelBackground(cornerRadius: 18, style: .elevated)
                            )
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text(sport.displayTitle)
                            .font(.headline)
                            .foregroundStyle(Color.appPrimary)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Training plans")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.25), value: path)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("My plans") {
                    showPlanManager = true
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .frame(minHeight: 44)
            }
        }
        .sheet(isPresented: $showPlanManager) {
            NavigationStack {
                ManageTrainingPlansView()
            }
            .environmentObject(fitness)
        }
        .alert("You can pin up to three favorites.", isPresented: $favoriteLimitAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    private func filteredPrograms(for sport: SportCategory) -> [TrainingProgramDefinition] {
        var list = fitness.mergedPrograms(for: sport)
        if let kind = activityScope.kind {
            list = list.filter { $0.activity == kind }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(q) || $0.subtitle.localizedCaseInsensitiveContains(q)
            }
        }
        return fitness.programsOrderedWithFavorites(list)
    }
}

private struct ProgramRow: View {
    @EnvironmentObject private var fitness: FitnessData
    let program: TrainingProgramDefinition
    var onFavoriteResult: (FavoriteToggleResult) -> Void

    private var isCustomPlan: Bool {
        CustomTrainingPlanSupport.isCustomPlanId(program.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.title)
                        .font(.headline)
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if isCustomPlan {
                        Text("Your plan")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                Spacer(minLength: 8)

                Button {
                    let r = fitness.toggleFavorite(programId: program.id)
                    onFavoriteResult(r)
                } label: {
                    Text(fitness.isFavorite(program.id) ? "★" : "☆")
                        .font(.title3)
                        .foregroundStyle(fitness.isFavorite(program.id) ? Color.appAccent : Color.appTextSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                StarRowView(filled: fitness.stars(for: program.id), animate: false)
                    .scaleEffect(0.75)
            }

            Text(program.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            ProgressView(value: fitness.completionRatio(for: program.id))
                .tint(Color.appAccent)
                .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}
