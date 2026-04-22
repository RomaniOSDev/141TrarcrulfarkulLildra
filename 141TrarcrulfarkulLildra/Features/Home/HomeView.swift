import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var fitness: FitnessData
    @EnvironmentObject private var tabRouter: TabRouter
    @State private var path: [TrainingDestination] = []

    private var calendarWeekday: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }

    private var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM")
        return formatter.string(from: Date())
    }

    private var todaysScheduledProgram: TrainingProgramDefinition? {
        guard let id = fitness.weeklySchedule.programId(forWeekday: calendarWeekday) else { return nil }
        return fitness.programDefinition(for: id)
    }

    private var favoritePrograms: [TrainingProgramDefinition] {
        fitness.favoriteProgramIds.compactMap { fitness.programDefinition(for: $0) }
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    heroWidget
                        .gridCellColumns(2)

                    iconStatTile(
                        value: "\(fitness.enduranceStreak)",
                        symbol: "flame.fill"
                    )
                    .accessibilityLabel("Session streak \(fitness.enduranceStreak) days")

                    iconStatTile(
                        value: "\(fitness.activeDaysStreak)",
                        symbol: "calendar"
                    )
                    .accessibilityLabel("Active days in a row \(fitness.activeDaysStreak)")

                    weeklyRingsWidget
                        .gridCellColumns(2)

                    if let program = todaysScheduledProgram {
                        todayPlanWidget(program: program)
                            .gridCellColumns(2)
                    } else {
                        emptyScheduleWidget
                            .gridCellColumns(2)
                    }

                    if !favoritePrograms.isEmpty {
                        favoritesWidget
                            .gridCellColumns(2)
                    }

                    statsWidget
                        .gridCellColumns(2)

                    quickActionsWidget
                        .gridCellColumns(2)

                    weeklyLayoutWidget
                        .gridCellColumns(2)
                }
                .padding()
            }
            
            .background(Color.clear)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TrainingDestination.self) { destination in
                TrainingDestinationHost(destination: destination, path: $path)
            }
        }
        .background(Color.clear)
    }

    // MARK: - Hero

    private var heroWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(shortFormattedDate)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(greetingLine)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "medal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                Text(fitness.achievementTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.appPrimary.opacity(0.1))
            )

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text("\(fitness.sessionsCompleted)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.appPrimary)
                }
                .accessibilityLabel("Sessions completed \(fitness.sessionsCompleted)")

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                    Text("\(fitness.totalStarsAcrossPrograms)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.appPrimary)
                }
                .accessibilityLabel("Stars total \(fitness.totalStarsAcrossPrograms)")

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface, Color.appPrimary.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.appAccent.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.appTextSecondary.opacity(0.1), radius: 12, x: 0, y: 6)
    }

    // MARK: - Compact icon + number (half width)

    private func iconStatTile(value: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .frame(width: 32, height: 32)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(12)
        .appChromePanel(style: .inset, cornerRadius: 16)
    }

    // MARK: - Weekly rings

    private var weeklyRingsWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "circle.grid.3x3")
                    .imageScale(.medium)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                Text("This week")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("This week progress")

            VStack(spacing: 14) {
                HomeRingGauge(
                    progress: fitness.weeklySessionProgress,
                    line1: "\(fitness.weeklySessionsCompleted)",
                    line2: "/ \(fitness.weeklySessionsTarget)",
                    captionSystemImage: "figure.run"
                )
                HomeRingGauge(
                    progress: fitness.weeklyMinutesProgress,
                    line1: "\(fitness.weeklyActiveMinutes)",
                    line2: "/ \(fitness.weeklyMinutesTarget)",
                    captionSystemImage: "clock"
                )
            }
            .frame(maxWidth: .infinity)

            if fitness.weeklySessionProgress >= 1, fitness.weeklyMinutesProgress >= 1 {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appAccent)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Weekly targets met")
            } else if fitness.weeklySessionProgress >= 1 || fitness.weeklyMinutesProgress >= 1 {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("On track this week")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .appChromePanel(style: .outlined, cornerRadius: 16)
    }

    // MARK: - Today’s plan

    private func todayPlanWidget(program: TrainingProgramDefinition) -> some View {
        let snap = fitness.lastSessionSnapshot(for: program.id)
        let stars = fitness.stars(for: program.id)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: sportSymbol(program.sport))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                Image(systemName: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(WeekdayFormatting.shortLabel(for: calendarWeekday))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                StarRowView(filled: stars, animate: false)
                    .scaleEffect(0.72)
            }

            Text(program.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.88)

            if let snap {
                HStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.caption.weight(.semibold))
                        Text("\(max(1, snap.elapsedSeconds / 60))m")
                            .font(.caption.weight(.semibold).monospacedDigit())
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                        Text("\(snap.starsEarned)")
                            .font(.caption.weight(.semibold).monospacedDigit())
                    }
                }
                .foregroundStyle(Color.appTextSecondary)
                .accessibilityLabel("Last session \(max(1, snap.elapsedSeconds / 60)) minutes, \(snap.starsEarned) stars")
            }

            Button {
                path.append(.programDetail(program))
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                    Spacer()
                }
                .foregroundStyle(Color.appTextOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .appPrimaryButtonChrome()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open plan")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .elevated, cornerRadius: 16)
    }

    private var emptyScheduleWidget: some View {
        VStack(alignment: .center, spacing: 14) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Color.appAccent)
            Text("No plan today")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)

            Button {
                tabRouter.selection = .training
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appTextOnPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .appPrimaryButtonChrome()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open training plans")
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(16)
        .appChromePanel(style: .outlined, cornerRadius: 16)
    }

    // MARK: - Favorites

    private var favoritesWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                    Text("\(favoritePrograms.count)/\(FitnessData.maxFavorites)")
                        .font(.headline.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.appPrimary)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Favorites \(favoritePrograms.count) of \(FitnessData.maxFavorites)")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(favoritePrograms) { program in
                        Button {
                            path.append(.programDetail(program))
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: sportSymbol(program.sport))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color.appAccent)
                                Text(program.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(12)
                            .frame(minWidth: 120, maxWidth: 150, minHeight: 80, alignment: .topLeading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.appSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.appAccent.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .inset, cornerRadius: 18)
    }

    // MARK: - Stats strip

    private var statsWidget: some View {
        HStack(spacing: 0) {
            statIconPill(
                value: "\(fitness.unlockedProgramIds.count)",
                symbol: "lock.open.fill",
                accessibility: "Unlocked programs \(fitness.unlockedProgramIds.count)"
            )
            Divider().frame(height: 40).background(Color.appTextSecondary.opacity(0.2))
            statIconPill(
                value: "\(fitness.customTrainingPlans.count)",
                symbol: "square.and.pencil",
                accessibility: "Custom plans \(fitness.customTrainingPlans.count)"
            )
            Divider().frame(height: 40).background(Color.appTextSecondary.opacity(0.2))
            statIconPill(
                value: "\(fitness.totalCaloriesEstimate)",
                symbol: "bolt.heart.fill",
                accessibility: "Estimated calories \(fitness.totalCaloriesEstimate)"
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .appChromePanel(style: .inset, cornerRadius: 16)
    }

    private func statIconPill(value: String, symbol: String, accessibility: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.appAccent)
            Text(value)
                .font(.headline.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibility)
    }

    // MARK: - Quick actions

    private var quickActionsWidget: some View {
        HStack(spacing: 10) {
            Button {
                tabRouter.selection = .training
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appTextOnPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .appPrimaryButtonChrome()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Training plans")

            Button {
                tabRouter.selection = .progress
            } label: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .appSecondaryOutlineChrome()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Progress")
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .appChromePanel(style: .inset, cornerRadius: 16)
    }

    private var weeklyLayoutWidget: some View {
        NavigationLink {
            WeeklyScheduleView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                Text("Weekly")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.appAccent.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Weekly schedule layout")
    }

    // MARK: - Helpers

    private func sportSymbol(_ sport: SportCategory) -> String {
        switch sport {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        }
    }

}

// MARK: - Ring gauge

private struct HomeRingGauge: View {
    let progress: Double
    let line1: String
    let line2: String
    let captionSystemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.appTextSecondary.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(min(1, progress)))
                    .stroke(
                        AngularGradient(
                            colors: [Color.appAccent, Color.appPrimary],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(line1)
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(line2)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .multilineTextAlignment(.center)
            }
            .frame(width: 64, height: 64)
            .fixedSize()

            Spacer(minLength: 0)

            Image(systemName: captionSystemImage)
                .font(.title2)
                .foregroundStyle(Color.appAccent)
                .frame(width: 32, height: 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
