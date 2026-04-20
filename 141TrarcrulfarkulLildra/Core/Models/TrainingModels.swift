import Foundation

enum SportCategory: String, CaseIterable, Identifiable, Codable {
    case running
    case cycling
    case swimming

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        }
    }
}

enum SessionDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var heartRateTolerance: Double {
        switch self {
        case .easy: return 18
        case .medium: return 12
        case .hard: return 8
        }
    }

    var cadenceTargetOffset: Int {
        switch self {
        case .easy: return -10
        case .medium: return 0
        case .hard: return 12
        }
    }

    var swimStrokeTarget: Int {
        switch self {
        case .easy: return 22
        case .medium: return 18
        case .hard: return 15
        }
    }

    var swimLapGoal: Int {
        switch self {
        case .easy: return 2
        case .medium: return 3
        case .hard: return 4
        }
    }
}

enum ActivityKind: String, Codable, CaseIterable {
    case heartRateZone
    case cadenceRhythm
    case swimStreamline

    var editorTitle: String {
        switch self {
        case .heartRateZone: return "Heart rate zone"
        case .cadenceRhythm: return "Cadence rhythm"
        case .swimStreamline: return "Swim streamline"
        }
    }
}

enum CustomTrainingPlanSupport {
    static let idPrefix = "custom-"

    static func isCustomPlanId(_ id: String) -> Bool {
        id.hasPrefix(idPrefix)
    }

    static func makeId() -> String {
        idPrefix + UUID().uuidString
    }
}

struct EditableTrainingPlan: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var sport: SportCategory
    var activity: ActivityKind
    var baseHeartRateTarget: Int
    var baseCadenceTarget: Int
    var sortOrder: Int

    func toDefinition() -> TrainingProgramDefinition {
        let safeTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return TrainingProgramDefinition(
            id: id,
            sport: sport,
            title: safeTitle.isEmpty ? "Untitled plan" : safeTitle,
            subtitle: safeSubtitle.isEmpty ? "Custom session" : safeSubtitle,
            activity: activity,
            baseHeartRateTarget: min(190, max(90, baseHeartRateTarget)),
            baseCadenceTarget: min(120, max(40, baseCadenceTarget)),
            orderIndex: 10_000 + sortOrder
        )
    }

    static func newDraft(sport: SportCategory) -> EditableTrainingPlan {
        EditableTrainingPlan(
            id: CustomTrainingPlanSupport.makeId(),
            title: "",
            subtitle: "",
            sport: sport,
            activity: .heartRateZone,
            baseHeartRateTarget: 130,
            baseCadenceTarget: 80,
            sortOrder: 0
        )
    }
}

struct TrainingProgramDefinition: Identifiable, Hashable {
    let id: String
    let sport: SportCategory
    let title: String
    let subtitle: String
    let activity: ActivityKind
    let baseHeartRateTarget: Int
    let baseCadenceTarget: Int
    let orderIndex: Int
}

enum TrainingCatalog {
    static let programs: [TrainingProgramDefinition] = [
        TrainingProgramDefinition(
            id: "run_hr_foundation",
            sport: .running,
            title: "Foundation Pace",
            subtitle: "Steady aerobic rhythm",
            activity: .heartRateZone,
            baseHeartRateTarget: 128,
            baseCadenceTarget: 85,
            orderIndex: 0
        ),
        TrainingProgramDefinition(
            id: "run_hr_tempo",
            sport: .running,
            title: "Tempo Sustain",
            subtitle: "Hold a strong aerobic line",
            activity: .heartRateZone,
            baseHeartRateTarget: 142,
            baseCadenceTarget: 90,
            orderIndex: 1
        ),
        TrainingProgramDefinition(
            id: "run_hr_power",
            sport: .running,
            title: "Power Threshold",
            subtitle: "Short surges with recovery windows",
            activity: .heartRateZone,
            baseHeartRateTarget: 156,
            baseCadenceTarget: 92,
            orderIndex: 2
        ),
        TrainingProgramDefinition(
            id: "cycle_cadence_spin",
            sport: .cycling,
            title: "Spin Stability",
            subtitle: "Smooth circles at controlled rpm",
            activity: .cadenceRhythm,
            baseHeartRateTarget: 130,
            baseCadenceTarget: 78,
            orderIndex: 3
        ),
        TrainingProgramDefinition(
            id: "cycle_cadence_climb",
            sport: .cycling,
            title: "Climb Rhythm",
            subtitle: "Lower gear, higher torque feel",
            activity: .cadenceRhythm,
            baseHeartRateTarget: 138,
            baseCadenceTarget: 68,
            orderIndex: 4
        ),
        TrainingProgramDefinition(
            id: "cycle_cadence_sprint",
            sport: .cycling,
            title: "Sprint Spin",
            subtitle: "Fast legs, stable core",
            activity: .cadenceRhythm,
            baseHeartRateTarget: 148,
            baseCadenceTarget: 95,
            orderIndex: 5
        ),
        TrainingProgramDefinition(
            id: "swim_breathe_steady",
            sport: .swimming,
            title: "Steady Breathing Ladder",
            subtitle: "Rhythmic exchanges per length",
            activity: .swimStreamline,
            baseHeartRateTarget: 124,
            baseCadenceTarget: 40,
            orderIndex: 6
        ),
        TrainingProgramDefinition(
            id: "swim_stroke_efficiency",
            sport: .swimming,
            title: "Stroke Efficiency",
            subtitle: "Fewer strokes, longer glide",
            activity: .swimStreamline,
            baseHeartRateTarget: 126,
            baseCadenceTarget: 38,
            orderIndex: 7
        ),
        TrainingProgramDefinition(
            id: "swim_threshold_mix",
            sport: .swimming,
            title: "Threshold Mix",
            subtitle: "Blend speed with calm breathing",
            activity: .swimStreamline,
            baseHeartRateTarget: 132,
            baseCadenceTarget: 36,
            orderIndex: 8
        )
    ]

    static func programs(for sport: SportCategory) -> [TrainingProgramDefinition] {
        programs.filter { $0.sport == sport }.sorted { $0.orderIndex < $1.orderIndex }
    }

    static func definition(for id: String) -> TrainingProgramDefinition? {
        programs.first { $0.id == id }
    }

    static func nextProgram(after id: String) -> TrainingProgramDefinition? {
        guard let current = definition(for: id) else { return nil }
        let ordered = programs.sorted { $0.orderIndex < $1.orderIndex }
        guard let idx = ordered.firstIndex(where: { $0.id == current.id }) else { return nil }
        let next = ordered.index(after: idx)
        if next < ordered.endIndex {
            return ordered[next]
        }
        return nil
    }
}

struct SessionOutcome: Hashable {
    let programId: String
    let activity: ActivityKind
    let starsEarned: Int
    let elapsedSeconds: Int
    let repsCompleted: Int
    let estimatedCalories: Int
    let ringCompletion: Double
    let milestoneUnlocked: Bool
    let performanceScore: Double
}
