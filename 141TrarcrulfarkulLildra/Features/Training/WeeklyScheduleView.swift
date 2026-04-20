import SwiftUI

struct WeeklyScheduleView: View {
    @EnvironmentObject private var fitness: FitnessData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Assign a suggested plan to each day. This is a visual guide only; you can still start any plan anytime.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appChromePanel(style: .inset, cornerRadius: 18)

                ForEach(1...7, id: \.self) { weekday in
                    dayRow(weekday: weekday)
                        .padding(12)
                        .appChromePanel(style: .outlined, cornerRadius: 18)
                }
            }
            .padding(16)
        }
        .background(Color.clear)
        .navigationTitle("Weekly layout")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dayRow(weekday: Int) -> some View {
        let currentId = fitness.weeklySchedule.programId(forWeekday: weekday)
        let currentTitle = currentId.flatMap { fitness.programDefinition(for: $0)?.title } ?? "None"

        return VStack(alignment: .leading, spacing: 10) {
            Text(WeekdayFormatting.shortLabel(for: weekday))
                .font(.headline)
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Menu {
                Button("Clear day") {
                    setSchedule(weekday: weekday, programId: nil)
                }
                ForEach(fitness.allProgramsForDisplay()) { program in
                    Button(program.title) {
                        setSchedule(weekday: weekday, programId: program.id)
                    }
                }
            } label: {
                HStack {
                    Text(currentTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Text("Choose")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appChromePanel(style: .elevated, cornerRadius: 16)
            }
        }
    }

    private func setSchedule(weekday: Int, programId: String?) {
        var next = fitness.weeklySchedule
        next.setProgramId(programId, weekday: weekday)
        fitness.updateWeeklySchedule(next)
    }
}
