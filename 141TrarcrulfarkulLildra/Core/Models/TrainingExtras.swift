import Foundation

struct SessionSnapshot: Codable, Hashable {
    var elapsedSeconds: Int
    var starsEarned: Int
    var ringCompletion: Double
    var recordedAt: Date
}

struct WeeklySchedule: Codable, Equatable {
    var slots: [String: String] = [:]

    func programId(forWeekday weekday: Int) -> String? {
        slots[String(weekday)]
    }

    mutating func setProgramId(_ programId: String?, weekday: Int) {
        let key = String(weekday)
        if let programId {
            slots[key] = programId
        } else {
            slots.removeValue(forKey: key)
        }
    }

    func allAssignedProgramIds() -> Set<String> {
        Set(slots.values)
    }
}

struct TrainingBackupPayload: Codable {
    var version: Int
    var customPlans: [EditableTrainingPlan]
    var favoriteProgramIds: [String]
    var weeklySchedule: WeeklySchedule
    var weeklySessionsTarget: Int
    var weeklyMinutesTarget: Int

    static let currentVersion = 1

    init(
        customPlans: [EditableTrainingPlan],
        favoriteProgramIds: [String],
        weeklySchedule: WeeklySchedule,
        weeklySessionsTarget: Int,
        weeklyMinutesTarget: Int
    ) {
        self.version = Self.currentVersion
        self.customPlans = customPlans
        self.favoriteProgramIds = favoriteProgramIds
        self.weeklySchedule = weeklySchedule
        self.weeklySessionsTarget = weeklySessionsTarget
        self.weeklyMinutesTarget = weeklyMinutesTarget
    }
}

enum FavoriteToggleResult {
    case added
    case removed
    case limitReached
    case notEligible
}

struct PreSessionMetrics {
    let snapshot: SessionSnapshot?
    let weeklySessionsCompleted: Int
    let weeklyActiveMinutes: Int
    let stars: Int
    let activeDaysStreak: Int
}

enum WeekdayFormatting {
    static func shortLabel(for weekday: Int) -> String {
        let cal = Calendar.current
        let symbols = cal.shortWeekdaySymbols
        guard weekday >= 1, weekday <= symbols.count else {
            return "Day \(weekday)"
        }
        return symbols[weekday - 1]
    }
}
