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

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
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

                    streakWidget(
                        title: "Session streak",
                        value: "\(fitness.enduranceStreak)",
                        caption: "days with a finish",
                        symbol: "flame.fill"
                    )

                    streakWidget(
                        title: "Active days",
                        value: "\(fitness.activeDaysStreak)",
                        caption: "in a row",
                        symbol: "calendar"
                    )

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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.appSurface)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.28),
                            Color.appAccent.opacity(0.18),
                            Color.appSurface.opacity(0.4),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.appAccent.opacity(0.2))
                .frame(width: 120, height: 120)
                .blur(radius: 28)
                .offset(x: 200, y: -30)

            Circle()
                .fill(Color.appPrimary.opacity(0.15))
                .frame(width: 90, height: 90)
                .blur(radius: 22)
                .offset(x: -20, y: 70)

            VStack(alignment: .leading, spacing: 14) {
                Text(formattedDate)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)

                Text(greetingLine)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text(fitness.achievementTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.appPrimary.opacity(0.12))
                    )

                Text("\(fitness.sessionsCompleted) sessions completed · \(fitness.totalStarsAcrossPrograms) stars earned")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.42), Color.appPrimary.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.appTextSecondary.opacity(0.14), radius: 26, x: 0, y: 14)
        .shadow(color: Color.appPrimary.opacity(0.12), radius: 10, x: 0, y: 5)
    }

    // MARK: - Small streak tiles

    private func streakWidget(title: String, value: String, caption: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .symbolRenderingMode(.hierarchical)

            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.appTextSecondary)
                .tracking(0.6)

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(caption)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .appChromePanel(style: .elevated, cornerRadius: 20)
    }

    // MARK: - Weekly rings

    private var weeklyRingsWidget: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This week")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                Spacer()
                Text("\(fitness.weeklySessionsCompleted)/\(fitness.weeklySessionsTarget) sessions")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }

            HStack(spacing: 20) {
                HomeRingGauge(
                    progress: fitness.weeklySessionProgress,
                    line1: "\(fitness.weeklySessionsCompleted)",
                    line2: "of \(fitness.weeklySessionsTarget)",
                    caption: "Sessions"
                )
                HomeRingGauge(
                    progress: fitness.weeklyMinutesProgress,
                    line1: "\(fitness.weeklyActiveMinutes)",
                    line2: "of \(fitness.weeklyMinutesTarget)",
                    caption: "Minutes"
                )
            }
            .frame(maxWidth: .infinity)

            if fitness.weeklySessionProgress >= 1, fitness.weeklyMinutesProgress >= 1 {
                Label("Weekly targets met — outstanding.", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            } else if fitness.weeklySessionProgress >= 1 || fitness.weeklyMinutesProgress >= 1 {
                Label("Keep going — you are on track.", systemImage: "arrow.up.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .outlined, cornerRadius: 20)
    }

    // MARK: - Today’s plan

    private func todayPlanWidget(program: TrainingProgramDefinition) -> some View {
        let snap = fitness.lastSessionSnapshot(for: program.id)
        let stars = fitness.stars(for: program.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: sportSymbol(program.sport))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scheduled today")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appTextSecondary)
                        .textCase(.uppercase)
                    Text(WeekdayFormatting.shortLabel(for: calendarWeekday))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                }
                Spacer()
                StarRowView(filled: stars, animate: false)
            }

            Text(program.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text(program.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let snap {
                Text(lastSessionSummary(snap))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Button {
                path.append(.programDetail(program))
            } label: {
                Text("Open plan")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .appPrimaryButtonChrome()
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .elevated, cornerRadius: 20)
    }

    private var emptyScheduleWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s slot")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appPrimary)
            Text("No plan is assigned for today. Add one in Weekly layout, or jump straight into Training.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                tabRouter.selection = .training
            } label: {
                Text("Browse training plans")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .appPrimaryButtonChrome()
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .outlined, cornerRadius: 20)
    }

    // MARK: - Favorites

    private var favoritesWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorites")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                Spacer()
                Text("\(favoritePrograms.count)/\(FitnessData.maxFavorites)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(favoritePrograms) { program in
                        Button {
                            path.append(.programDetail(program))
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Image(systemName: sportSymbol(program.sport))
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.appAccent)
                                Text(program.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Text(program.sport.displayTitle)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            .padding(14)
                            .frame(width: 148, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.appSurface,
                                                Color.appPrimary.opacity(0.1),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.appAccent.opacity(0.4), Color.appPrimary.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.appTextSecondary.opacity(0.12), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .elevated, cornerRadius: 20)
    }

    // MARK: - Stats strip

    private var statsWidget: some View {
        HStack(spacing: 0) {
            statPill(title: "Unlocked", value: "\(fitness.unlockedProgramIds.count)", symbol: "lock.open.fill")
            Divider().frame(height: 36).background(Color.appTextSecondary.opacity(0.2))
            statPill(title: "Custom plans", value: "\(fitness.customTrainingPlans.count)", symbol: "square.and.pencil")
            Divider().frame(height: 36).background(Color.appTextSecondary.opacity(0.2))
            statPill(title: "Est. kcal", value: "\(fitness.totalCaloriesEstimate)", symbol: "bolt.heart.fill")
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .appChromePanel(style: .elevated, cornerRadius: 20)
    }

    private func statPill(title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appAccent)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick actions

    private var quickActionsWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shortcuts")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appPrimary)

            HStack(spacing: 10) {
                Button {
                    tabRouter.selection = .training
                } label: {
                    Label("Training", systemImage: "list.bullet.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .appPrimaryButtonChrome()
                }
                .buttonStyle(.plain)

                Button {
                    tabRouter.selection = .progress
                } label: {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .appSecondaryOutlineChrome()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .elevated, cornerRadius: 20)
    }

    private var weeklyLayoutWidget: some View {
        NavigationLink {
            WeeklyScheduleView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.appPrimary.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "calendar.badge.clock")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly layout")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Map plans to weekdays")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appSurface.opacity(0.95), Color.appPrimary.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.45), Color.appPrimary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: Color.appAccent.opacity(0.14), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sportSymbol(_ sport: SportCategory) -> String {
        switch sport {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        }
    }

    private func lastSessionSummary(_ snap: SessionSnapshot) -> String {
        let minutes = max(1, snap.elapsedSeconds / 60)
        return "Last time: \(minutes) min · \(snap.starsEarned) stars"
    }
}

// MARK: - Ring gauge

private struct HomeRingGauge: View {
    let progress: Double
    let line1: String
    let line2: String
    let caption: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.appTextSecondary.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(min(1, progress)))
                    .stroke(
                        AngularGradient(
                            colors: [Color.appAccent, Color.appPrimary],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(line1)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                    Text(line2)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .frame(width: 108, height: 108)

            Text(caption)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
