import SwiftUI

struct ProgressHubView: View {
    @EnvironmentObject private var fitness: FitnessData

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summarySection
                    starsSection
                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack {
                            Text("Settings & data")
                                .font(.headline)
                                .foregroundStyle(Color.appPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer()
                            ChevronGlyph()
                        }
                        .padding(16)
                        .appChromePanel(style: .elevated, cornerRadius: 18)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(Color.clear)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.clear)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Totals")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            statLine(title: "Sessions finished", value: "\(fitness.sessionsCompleted)")
            statLine(title: "Active streak", value: "\(fitness.enduranceStreak) days")
            statLine(title: "Estimated calories", value: "\(fitness.totalCaloriesEstimate) kcal")
            statLine(title: "Tracked reps", value: "\(fitness.totalRepsTracked)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .elevated, cornerRadius: 20)
    }

    private func statLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Text(value)
                .foregroundStyle(Color.appPrimary)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var starsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program stars")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if fitness.allProgramsForDisplay().allSatisfy({ fitness.stars(for: $0.id) == 0 }) {
                Text("Complete sessions to start collecting stars across programs.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(fitness.allProgramsForDisplay()) { program in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(program.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(program.sport.displayTitle)
                                .font(.caption)
                                .foregroundStyle(Color.appTextSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer()
                        StarRowView(filled: fitness.stars(for: program.id), animate: false)
                            .scaleEffect(0.8)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .outlined, cornerRadius: 20)
    }
}
