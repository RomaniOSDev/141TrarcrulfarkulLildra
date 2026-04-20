import Combine
import Foundation

@MainActor
final class FitnessData: ObservableObject {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let enduranceStreak = "enduranceStreak"
        static let sessionsCompleted = "sessionsCompleted"
        static let bestTimes = "bestTimes"
        static let starsByProgram = "starsByProgram"
        static let unlockedProgramIds = "unlockedProgramIds"
        static let lastCompletionDay = "lastCompletionDay"
        static let totalCaloriesEstimate = "totalCaloriesEstimate"
        static let totalRepsTracked = "totalRepsTracked"
        static let customTrainingPlansJSON = "customTrainingPlansJSON"
        static let favoriteProgramIdsJSON = "favoriteProgramIdsJSON"
        static let sessionSnapshotsJSON = "sessionSnapshotsJSON"
        static let weeklyScheduleJSON = "weeklyScheduleJSON"
        static let weeklySessionsTarget = "weeklySessionsTarget"
        static let weeklyMinutesTarget = "weeklyMinutesTarget"
        static let weeklyBucketYear = "weeklyBucketYear"
        static let weeklyBucketWeek = "weeklyBucketWeek"
        static let weeklySessionsCount = "weeklySessionsCount"
        static let weeklyMinutesCount = "weeklyMinutesCount"
        static let activeDaysStreak = "activeDaysStreak"
        static let lastActiveSessionDayISO = "lastActiveSessionDayISO"
    }

    static let maxFavorites = 3

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var enduranceStreak: Int
    @Published private(set) var sessionsCompleted: Int
    @Published private(set) var bestTimes: [String: Double]
    @Published private(set) var starsByProgram: [String: Int]
    @Published private(set) var unlockedProgramIds: Set<String>
    @Published private(set) var totalCaloriesEstimate: Int
    @Published private(set) var totalRepsTracked: Int
    @Published private(set) var customTrainingPlans: [EditableTrainingPlan] = []
    @Published private(set) var favoriteProgramIds: [String] = []
    @Published private(set) var weeklySchedule: WeeklySchedule = WeeklySchedule()
    @Published private(set) var weeklySessionsTarget: Int
    @Published private(set) var weeklyMinutesTarget: Int
    @Published private(set) var weeklySessionsCompleted: Int
    @Published private(set) var weeklyActiveMinutes: Int
    @Published private(set) var activeDaysStreak: Int

    private var sessionSnapshots: [String: SessionSnapshot] = [:]

    private var cancellables = Set<AnyCancellable>()

    init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        enduranceStreak = defaults.integer(forKey: Keys.enduranceStreak)
        sessionsCompleted = defaults.integer(forKey: Keys.sessionsCompleted)
        bestTimes = FitnessData.decodeDoubleDictionary(from: defaults.string(forKey: Keys.bestTimes))
        starsByProgram = FitnessData.decodeIntDictionary(from: defaults.string(forKey: Keys.starsByProgram))
        totalCaloriesEstimate = defaults.integer(forKey: Keys.totalCaloriesEstimate)
        totalRepsTracked = defaults.integer(forKey: Keys.totalRepsTracked)

        let wST = defaults.integer(forKey: Keys.weeklySessionsTarget)
        weeklySessionsTarget = wST > 0 ? wST : 4
        let wMT = defaults.integer(forKey: Keys.weeklyMinutesTarget)
        weeklyMinutesTarget = wMT > 0 ? wMT : 90

        weeklySessionsCompleted = defaults.integer(forKey: Keys.weeklySessionsCount)
        weeklyActiveMinutes = defaults.integer(forKey: Keys.weeklyMinutesCount)
        activeDaysStreak = defaults.integer(forKey: Keys.activeDaysStreak)

        sessionSnapshots = FitnessData.decodeSnapshots(from: defaults.string(forKey: Keys.sessionSnapshotsJSON))
        weeklySchedule = FitnessData.decodeWeeklySchedule(from: defaults.string(forKey: Keys.weeklyScheduleJSON))
        favoriteProgramIds = FitnessData.decodeStringArray(from: defaults.string(forKey: Keys.favoriteProgramIdsJSON))

        let unlocked = FitnessData.decodeStringArray(from: defaults.string(forKey: Keys.unlockedProgramIds))
        if unlocked.isEmpty {
            let firstIds = SportCategory.allCases.compactMap { sport in
                TrainingCatalog.programs(for: sport).first?.id
            }
            unlockedProgramIds = Set(firstIds)
            defaults.set(Array(unlockedProgramIds).sorted().joined(separator: ","), forKey: Keys.unlockedProgramIds)
        } else {
            unlockedProgramIds = Set(FitnessData.unlockedSanitized(unlocked))
        }

        loadCustomTrainingPlansFromDefaults()
        normalizeWeekBucketIfNeeded()

        NotificationCenter.default.publisher(for: .dataRefreshed)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadFromDefaults()
            }
            .store(in: &cancellables)
    }

    private func reloadFromDefaults() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        enduranceStreak = defaults.integer(forKey: Keys.enduranceStreak)
        sessionsCompleted = defaults.integer(forKey: Keys.sessionsCompleted)
        bestTimes = FitnessData.decodeDoubleDictionary(from: defaults.string(forKey: Keys.bestTimes))
        starsByProgram = FitnessData.decodeIntDictionary(from: defaults.string(forKey: Keys.starsByProgram))
        totalCaloriesEstimate = defaults.integer(forKey: Keys.totalCaloriesEstimate)
        totalRepsTracked = defaults.integer(forKey: Keys.totalRepsTracked)

        let wST = defaults.integer(forKey: Keys.weeklySessionsTarget)
        weeklySessionsTarget = wST > 0 ? wST : 4
        let wMT = defaults.integer(forKey: Keys.weeklyMinutesTarget)
        weeklyMinutesTarget = wMT > 0 ? wMT : 90

        weeklySessionsCompleted = defaults.integer(forKey: Keys.weeklySessionsCount)
        weeklyActiveMinutes = defaults.integer(forKey: Keys.weeklyMinutesCount)
        activeDaysStreak = defaults.integer(forKey: Keys.activeDaysStreak)

        sessionSnapshots = FitnessData.decodeSnapshots(from: defaults.string(forKey: Keys.sessionSnapshotsJSON))
        weeklySchedule = FitnessData.decodeWeeklySchedule(from: defaults.string(forKey: Keys.weeklyScheduleJSON))
        favoriteProgramIds = FitnessData.decodeStringArray(from: defaults.string(forKey: Keys.favoriteProgramIdsJSON))

        let unlocked = FitnessData.decodeStringArray(from: defaults.string(forKey: Keys.unlockedProgramIds))
        unlockedProgramIds = Set(FitnessData.unlockedSanitized(unlocked))
        loadCustomTrainingPlansFromDefaults()
        normalizeWeekBucketIfNeeded()
    }

    private func loadCustomTrainingPlansFromDefaults() {
        customTrainingPlans = FitnessData.decodeCustomPlans(from: defaults.string(forKey: Keys.customTrainingPlansJSON))
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func persistCustomTrainingPlans() {
        defaults.set(FitnessData.encodeCustomPlans(customTrainingPlans), forKey: Keys.customTrainingPlansJSON)
    }

    private func persistFavorites() {
        defaults.set(FitnessData.encodeStringArray(favoriteProgramIds), forKey: Keys.favoriteProgramIdsJSON)
    }

    private func persistSnapshots() {
        defaults.set(FitnessData.encodeSnapshots(sessionSnapshots), forKey: Keys.sessionSnapshotsJSON)
    }

    private func persistWeeklySchedule() {
        defaults.set(FitnessData.encodeWeeklySchedule(weeklySchedule), forKey: Keys.weeklyScheduleJSON)
    }

    func upsertCustomTrainingPlan(_ plan: EditableTrainingPlan) {
        var next = customTrainingPlans
        if let idx = next.firstIndex(where: { $0.id == plan.id }) {
            next[idx] = plan
        } else {
            next.append(plan)
        }
        customTrainingPlans = next.sorted { $0.sortOrder < $1.sortOrder }
        persistCustomTrainingPlans()
        objectWillChange.send()
    }

    func duplicateCatalogProgram(_ definition: TrainingProgramDefinition) -> EditableTrainingPlan {
        let nextOrder = (customTrainingPlans.filter { $0.sport == definition.sport }.map(\.sortOrder).max() ?? 0) + 1
        var plan = EditableTrainingPlan.newDraft(sport: definition.sport)
        plan.title = definition.title + " copy"
        plan.subtitle = definition.subtitle
        plan.activity = definition.activity
        plan.baseHeartRateTarget = definition.baseHeartRateTarget
        plan.baseCadenceTarget = definition.baseCadenceTarget
        plan.sortOrder = nextOrder
        upsertCustomTrainingPlan(plan)
        return plan
    }

    func deleteCustomTrainingPlan(id: String) {
        customTrainingPlans.removeAll { $0.id == id }
        persistCustomTrainingPlans()

        favoriteProgramIds.removeAll { $0 == id }
        persistFavorites()

        var schedule = weeklySchedule
        for weekday in 1...7 {
            if schedule.programId(forWeekday: weekday) == id {
                schedule.setProgramId(nil, weekday: weekday)
            }
        }
        weeklySchedule = schedule
        persistWeeklySchedule()

        var st = starsByProgram
        st.removeValue(forKey: id)
        starsByProgram = st
        defaults.set(FitnessData.encodeIntDictionary(st), forKey: Keys.starsByProgram)

        var bt = bestTimes
        bt.removeValue(forKey: id)
        bestTimes = bt
        defaults.set(FitnessData.encodeDoubleDictionary(bt), forKey: Keys.bestTimes)

        sessionSnapshots.removeValue(forKey: id)
        persistSnapshots()

        unlockedProgramIds.remove(id)
        defaults.set(Array(unlockedProgramIds).sorted().joined(separator: ","), forKey: Keys.unlockedProgramIds)

        objectWillChange.send()
    }

    func programDefinition(for id: String) -> TrainingProgramDefinition? {
        if let builtIn = TrainingCatalog.definition(for: id) {
            return builtIn
        }
        return customTrainingPlans.first(where: { $0.id == id })?.toDefinition()
    }

    func mergedPrograms(for sport: SportCategory) -> [TrainingProgramDefinition] {
        let customs = customTrainingPlans
            .filter { $0.sport == sport }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { $0.toDefinition() }
        return customs + TrainingCatalog.programs(for: sport)
    }

    func programsOrderedWithFavorites(_ programs: [TrainingProgramDefinition]) -> [TrainingProgramDefinition] {
        let favSet = Set(favoriteProgramIds)
        let favs = favoriteProgramIds.compactMap { fid in programs.first { $0.id == fid } }
        let rest = programs.filter { !favSet.contains($0.id) }
        return favs + rest
    }

    func nextProgram(after programId: String) -> TrainingProgramDefinition? {
        guard let sport = programDefinition(for: programId)?.sport else { return nil }
        let ordered = mergedPrograms(for: sport)
        guard let idx = ordered.firstIndex(where: { $0.id == programId }) else { return nil }
        let nextIdx = ordered.index(after: idx)
        if nextIdx < ordered.endIndex {
            return ordered[nextIdx]
        }
        return nil
    }

    func allProgramsForDisplay() -> [TrainingProgramDefinition] {
        SportCategory.allCases.flatMap { mergedPrograms(for: $0) }
    }

    func lastSessionSnapshot(for programId: String) -> SessionSnapshot? {
        sessionSnapshots[programId]
    }

    func weeklySessionsCompletedForCurrentWeek() -> Int {
        normalizeWeekBucketIfNeeded()
        return weeklySessionsCompleted
    }

    func capturePreSessionMetrics(for programId: String) -> PreSessionMetrics {
        normalizeWeekBucketIfNeeded()
        return PreSessionMetrics(
            snapshot: lastSessionSnapshot(for: programId),
            weeklySessionsCompleted: weeklySessionsCompleted,
            weeklyActiveMinutes: weeklyActiveMinutes,
            stars: stars(for: programId),
            activeDaysStreak: activeDaysStreak
        )
    }

    func isFavorite(_ programId: String) -> Bool {
        favoriteProgramIds.contains(programId)
    }

    @discardableResult
    func toggleFavorite(programId: String) -> FavoriteToggleResult {
        if let idx = favoriteProgramIds.firstIndex(of: programId) {
            favoriteProgramIds.remove(at: idx)
            persistFavorites()
            objectWillChange.send()
            return .removed
        }
        guard programDefinition(for: programId) != nil else { return .notEligible }
        if favoriteProgramIds.count >= Self.maxFavorites {
            return .limitReached
        }
        var next = favoriteProgramIds
        next.insert(programId, at: 0)
        favoriteProgramIds = Array(next.prefix(Self.maxFavorites))
        persistFavorites()
        objectWillChange.send()
        return .added
    }

    func updateWeeklySchedule(_ schedule: WeeklySchedule) {
        weeklySchedule = schedule
        persistWeeklySchedule()
        objectWillChange.send()
    }

    func setWeeklySessionTarget(_ value: Int) {
        let v = max(1, min(21, value))
        weeklySessionsTarget = v
        defaults.set(v, forKey: Keys.weeklySessionsTarget)
        objectWillChange.send()
    }

    func setWeeklyMinutesTarget(_ value: Int) {
        let v = max(15, min(900, value))
        weeklyMinutesTarget = v
        defaults.set(v, forKey: Keys.weeklyMinutesTarget)
        objectWillChange.send()
    }

    var weeklySessionProgress: Double {
        guard weeklySessionsTarget > 0 else { return 0 }
        return min(1.0, Double(weeklySessionsCompleted) / Double(weeklySessionsTarget))
    }

    var weeklyMinutesProgress: Double {
        guard weeklyMinutesTarget > 0 else { return 0 }
        return min(1.0, Double(weeklyActiveMinutes) / Double(weeklyMinutesTarget))
    }

    var totalStarsAcrossPrograms: Int {
        starsByProgram.values.reduce(0, +)
    }

    func weeklySessionGoalJustCompleted(beforeCount: Int) -> Bool {
        weeklySessionsCompleted >= weeklySessionsTarget && beforeCount < weeklySessionsTarget
    }

    func weeklyMinutesGoalJustCompleted(beforeMinutes: Int) -> Bool {
        weeklyActiveMinutes >= weeklyMinutesTarget && beforeMinutes < weeklyMinutesTarget
    }

    func makeBackupPayload() -> TrainingBackupPayload {
        TrainingBackupPayload(
            customPlans: customTrainingPlans,
            favoriteProgramIds: favoriteProgramIds,
            weeklySchedule: weeklySchedule,
            weeklySessionsTarget: weeklySessionsTarget,
            weeklyMinutesTarget: weeklyMinutesTarget
        )
    }

    func importBackupPayload(_ payload: TrainingBackupPayload) {
        for plan in payload.customPlans {
            upsertCustomTrainingPlan(plan)
        }
        favoriteProgramIds = Array(payload.favoriteProgramIds.prefix(Self.maxFavorites))
        persistFavorites()
        weeklySchedule = payload.weeklySchedule
        persistWeeklySchedule()
        setWeeklySessionTarget(payload.weeklySessionsTarget)
        setWeeklyMinutesTarget(payload.weeklyMinutesTarget)
        objectWillChange.send()
    }

    private static func unlockedSanitized(_ values: [String]) -> [String] {
        if values.isEmpty {
            return SportCategory.allCases.compactMap { sport in
                TrainingCatalog.programs(for: sport).first?.id
            }
        }
        return values
    }

    func completeOnboarding() {
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
        hasSeenOnboarding = true
    }

    var achievementTitle: String {
        switch sessionsCompleted {
        case 0: return "Begin your path"
        case 1..<5: return "Committed starter"
        case 5..<15: return "Focused athlete"
        case 15..<30: return "Long-form specialist"
        default: return "Elite consistency"
        }
    }

    func completionRatio(for programId: String) -> Double {
        let stars = starsByProgram[programId, default: 0]
        return min(1.0, Double(stars) / 3.0)
    }

    func stars(for programId: String) -> Int {
        starsByProgram[programId, default: 0]
    }

    func isUnlocked(programId: String) -> Bool {
        if CustomTrainingPlanSupport.isCustomPlanId(programId) {
            return true
        }
        return unlockedProgramIds.contains(programId)
    }

    func recordSessionOutcome(_ outcome: SessionOutcome) {
        sessionsCompleted += 1
        defaults.set(sessionsCompleted, forKey: Keys.sessionsCompleted)

        let previousStars = starsByProgram[outcome.programId, default: 0]
        if outcome.starsEarned > previousStars {
            var updatedStars = starsByProgram
            updatedStars[outcome.programId] = outcome.starsEarned
            starsByProgram = updatedStars
            defaults.set(FitnessData.encodeIntDictionary(updatedStars), forKey: Keys.starsByProgram)
        }

        let previousBest = bestTimes[outcome.programId, default: 0]
        let candidate = outcome.performanceScore
        if candidate > previousBest {
            var updatedBest = bestTimes
            updatedBest[outcome.programId] = candidate
            bestTimes = updatedBest
            defaults.set(FitnessData.encodeDoubleDictionary(updatedBest), forKey: Keys.bestTimes)
        }

        totalCaloriesEstimate += max(0, outcome.estimatedCalories)
        defaults.set(totalCaloriesEstimate, forKey: Keys.totalCaloriesEstimate)

        totalRepsTracked += max(0, outcome.repsCompleted)
        defaults.set(totalRepsTracked, forKey: Keys.totalRepsTracked)

        sessionSnapshots[outcome.programId] = SessionSnapshot(
            elapsedSeconds: outcome.elapsedSeconds,
            starsEarned: outcome.starsEarned,
            ringCompletion: outcome.ringCompletion,
            recordedAt: Date()
        )
        persistSnapshots()

        normalizeWeekBucketIfNeeded()
        weeklySessionsCompleted += 1
        weeklyActiveMinutes += max(0, outcome.elapsedSeconds / 60)
        defaults.set(weeklySessionsCompleted, forKey: Keys.weeklySessionsCount)
        defaults.set(weeklyActiveMinutes, forKey: Keys.weeklyMinutesCount)

        updateActiveDaysStreak()

        updateStreakIfNeeded()
        if outcome.starsEarned >= 1 {
            unlockFollowUps(for: outcome.programId)
        }

        objectWillChange.send()
    }

    private func updateActiveDaysStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        if let lastString = defaults.string(forKey: Keys.lastActiveSessionDayISO),
           let lastDate = formatter.date(from: lastString) {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay == today {
                defaults.set(activeDaysStreak, forKey: Keys.activeDaysStreak)
                return
            }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
               lastDay == yesterday {
                activeDaysStreak += 1
            } else {
                activeDaysStreak = 1
            }
        } else {
            activeDaysStreak = max(1, activeDaysStreak)
        }
        defaults.set(activeDaysStreak, forKey: Keys.activeDaysStreak)
        defaults.set(formatter.string(from: today), forKey: Keys.lastActiveSessionDayISO)
    }

    private func normalizeWeekBucketIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        let y = calendar.component(.yearForWeekOfYear, from: now)
        let w = calendar.component(.weekOfYear, from: now)
        let sy = defaults.integer(forKey: Keys.weeklyBucketYear)
        let sw = defaults.integer(forKey: Keys.weeklyBucketWeek)
        if sy == 0 && sw == 0 {
            defaults.set(y, forKey: Keys.weeklyBucketYear)
            defaults.set(w, forKey: Keys.weeklyBucketWeek)
            return
        }
        if sy != y || sw != w {
            weeklySessionsCompleted = 0
            weeklyActiveMinutes = 0
            defaults.set(0, forKey: Keys.weeklySessionsCount)
            defaults.set(0, forKey: Keys.weeklyMinutesCount)
            defaults.set(y, forKey: Keys.weeklyBucketYear)
            defaults.set(w, forKey: Keys.weeklyBucketWeek)
        }
    }

    private func updateStreakIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()
        if let lastString = defaults.string(forKey: Keys.lastCompletionDay),
           let lastDate = formatter.date(from: lastString) {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay == today {
                return
            }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
               lastDay == yesterday {
                enduranceStreak += 1
            } else {
                enduranceStreak = 1
            }
        } else {
            enduranceStreak = 1
        }
        defaults.set(enduranceStreak, forKey: Keys.enduranceStreak)
        defaults.set(formatter.string(from: today), forKey: Keys.lastCompletionDay)
    }

    private func unlockFollowUps(for programId: String) {
        if let next = nextProgram(after: programId) {
            unlockedProgramIds.insert(next.id)
        }
        defaults.set(Array(unlockedProgramIds).sorted().joined(separator: ","), forKey: Keys.unlockedProgramIds)
    }

    func resetAllProgress() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        let customBackup = defaults.string(forKey: Keys.customTrainingPlansJSON)
        let favoritesBackup = defaults.string(forKey: Keys.favoriteProgramIdsJSON)
        let scheduleBackup = defaults.string(forKey: Keys.weeklyScheduleJSON)
        let wST = defaults.integer(forKey: Keys.weeklySessionsTarget)
        let wMT = defaults.integer(forKey: Keys.weeklyMinutesTarget)

        defaults.removePersistentDomain(forName: bundleIdentifier)
        defaults.synchronize()
        reloadFromDefaults()

        if let customBackup {
            defaults.set(customBackup, forKey: Keys.customTrainingPlansJSON)
            loadCustomTrainingPlansFromDefaults()
        }
        if let favoritesBackup {
            defaults.set(favoritesBackup, forKey: Keys.favoriteProgramIdsJSON)
            favoriteProgramIds = FitnessData.decodeStringArray(from: favoritesBackup)
        }
        if let scheduleBackup {
            defaults.set(scheduleBackup, forKey: Keys.weeklyScheduleJSON)
            weeklySchedule = FitnessData.decodeWeeklySchedule(from: scheduleBackup)
        }
        let sessionsT = wST > 0 ? wST : 4
        let minutesT = wMT > 0 ? wMT : 90
        defaults.set(sessionsT, forKey: Keys.weeklySessionsTarget)
        defaults.set(minutesT, forKey: Keys.weeklyMinutesTarget)
        weeklySessionsTarget = sessionsT
        weeklyMinutesTarget = minutesT

        let firstIds = SportCategory.allCases.compactMap { sport in
            TrainingCatalog.programs(for: sport).first?.id
        }
        unlockedProgramIds = Set(firstIds)
        defaults.set(Array(unlockedProgramIds).sorted().joined(separator: ","), forKey: Keys.unlockedProgramIds)
        objectWillChange.send()
        NotificationCenter.default.post(name: .dataRefreshed, object: nil)
    }

    private static func decodeDoubleDictionary(from string: String?) -> [String: Double] {
        guard let string, let data = string.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: Double].self, from: data)) ?? [:]
    }

    private static func encodeDoubleDictionary(_ dict: [String: Double]) -> String {
        guard let data = try? JSONEncoder().encode(dict), let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    private static func decodeIntDictionary(from string: String?) -> [String: Int] {
        guard let string, let data = string.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
    }

    private static func encodeIntDictionary(_ dict: [String: Int]) -> String {
        guard let data = try? JSONEncoder().encode(dict), let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    private static func decodeStringArray(from string: String?) -> [String] {
        guard let string, !string.isEmpty else { return [] }
        if let data = string.data(using: .utf8),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            return arr
        }
        return string.split(separator: ",").map(String.init)
    }

    private static func encodeStringArray(_ array: [String]) -> String {
        guard let data = try? JSONEncoder().encode(array), let str = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return str
    }

    private static func decodeCustomPlans(from string: String?) -> [EditableTrainingPlan] {
        guard let string, let data = string.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([EditableTrainingPlan].self, from: data)) ?? []
    }

    private static func encodeCustomPlans(_ plans: [EditableTrainingPlan]) -> String {
        guard let data = try? JSONEncoder().encode(plans), let str = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return str
    }

    private static func decodeSnapshots(from string: String?) -> [String: SessionSnapshot] {
        guard let string, let data = string.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: SessionSnapshot].self, from: data)) ?? [:]
    }

    private static func encodeSnapshots(_ dict: [String: SessionSnapshot]) -> String {
        guard let data = try? JSONEncoder().encode(dict), let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    private static func decodeWeeklySchedule(from string: String?) -> WeeklySchedule {
        guard let string, let data = string.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(WeeklySchedule.self, from: data) else {
            return WeeklySchedule()
        }
        return decoded
    }

    private static func encodeWeeklySchedule(_ schedule: WeeklySchedule) -> String {
        guard let data = try? JSONEncoder().encode(schedule), let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }
}
