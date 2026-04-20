import SwiftUI

struct ManageTrainingPlansView: View {
    @EnvironmentObject private var fitness: FitnessData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if fitness.customTrainingPlans.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("No custom plans yet")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("Tap Add to create a plan. You choose sport, session type, and target numbers. Custom plans stay unlocked and appear above the built-in library in each sport section.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appChromePanel(style: .outlined, cornerRadius: 22)
                    .padding(16)
                }
                .appMeshScreenBackground()
            } else {
                List {
                    ForEach(SportCategory.allCases) { sport in
                        let plans = fitness.customTrainingPlans.filter { $0.sport == sport }
                        if !plans.isEmpty {
                            Section {
                                ForEach(plans) { plan in
                                    NavigationLink {
                                        PlanEditorView(plan: plan)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(plan.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled plan" : plan.title)
                                                .font(.headline)
                                                .foregroundStyle(Color.appPrimary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                            Text(plan.activity.editorTitle)
                                                .font(.caption)
                                                .foregroundStyle(Color.appTextSecondary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(
                                        AppPanelBackground(cornerRadius: 18, style: .elevated)
                                    )
                                    .listRowSeparator(.hidden)
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        fitness.deleteCustomTrainingPlan(id: plans[index].id)
                                    }
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
                .appMeshScreenBackground()
            }
        }
        .navigationTitle("Your plans")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
                .frame(minHeight: 44)
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    PlanEditorView(plan: nil)
                } label: {
                    Text("Add")
                        .font(.body.weight(.semibold))
                }
                .frame(minHeight: 44)
            }
        }
    }
}
