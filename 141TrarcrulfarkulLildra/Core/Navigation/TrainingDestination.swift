import Foundation

enum TrainingDestination: Hashable {
    case programDetail(TrainingProgramDefinition)
    case heartSession(program: TrainingProgramDefinition, difficulty: SessionDifficulty)
    case cadenceSession(program: TrainingProgramDefinition, difficulty: SessionDifficulty)
    case swimSession(program: TrainingProgramDefinition, difficulty: SessionDifficulty)
    case sessionResult(
        SessionOutcome,
        nextProgram: TrainingProgramDefinition?,
        previousSnapshot: SessionSnapshot?,
        weeklySessionsBefore: Int,
        weeklyMinutesBefore: Int,
        starsBefore: Int,
        activeDaysStreakBefore: Int
    )
}
