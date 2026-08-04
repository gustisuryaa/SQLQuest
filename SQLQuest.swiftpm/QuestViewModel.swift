import SwiftUI

// MARK: - Quest Phase State Machine

enum QuestPhase: Equatable {
    case hub
    case challenge
    case feedback
    case summary
}

// MARK: - QuestViewModel

@MainActor
final class QuestViewModel: ObservableObject {

    // MARK: - Phase
    @Published var currentPhase: QuestPhase = .hub
    @Published var currentQuestIndex: Int   = 0

    // MARK: - Multiple Choice / SQL Builder state
    @Published var selectedToken: JoinType? = nil

    // MARK: - Sequence Order state
    // The user's current arrangement of SQL clauses (by their index in quest.sqlClauses)
    @Published var arrangedIndices: [Int] = []

    // MARK: - Common challenge state
    @Published var isCorrect : Bool  = false
    @Published var showHint  : Bool  = false
    @Published var hintsUsed : Int   = 0
    @Published var xpEarned  : Int   = 0

    // MARK: - Session stats
    @Published var sessionXP       : Int = 0
    @Published var questsAttempted : Int = 0
    @Published var questsCorrect   : Int = 0

    // MARK: - Timer
    @Published var timeRemaining: Double = 60.0
    private var timerTask: Task<Void, Never>?

    // MARK: - Data
    let quests = questData

    // MARK: - Computed

    var currentQuest: Quest? {
        guard currentQuestIndex < quests.count else { return nil }
        return quests[currentQuestIndex]
    }

    var accuracy: Int {
        guard questsAttempted > 0 else { return 0 }
        return Int((Double(questsCorrect) / Double(questsAttempted)) * 100)
    }

    // Sequence Order: the correct order of indices (0, 1, 2, 3)
    var correctSequence: [Int] {
        guard let quest = currentQuest,
              let clauses = quest.sqlClauses else { return [] }
        // Correct SQL order: SELECT → FROM → JOIN → ON
        let correctOrder = ["SELECT *", "FROM Students", "\(quest.correctJoin.rawValue) Clubs", "ON Students.id = Clubs.id"]
        return correctOrder.compactMap { target in clauses.firstIndex(of: target) }
    }

    var sequenceIsCorrect: Bool {
        arrangedIndices == correctSequence
    }

    // MARK: - Actions

    func startQuest(at index: Int) {
        currentQuestIndex = index
        selectedToken     = nil
        arrangedIndices   = []
        showHint          = false
        hintsUsed         = 0
        timeRemaining     = currentQuest?.difficulty.timeLimit ?? 45

        withAnimation(.easeInOut(duration: 0.3)) { currentPhase = .challenge }
        startTimer()
    }

    func revealHint() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showHint  = true
            hintsUsed += 1
        }
    }

    // MARK: Sequence Order mechanic actions

    func appendToSequence(index: Int) {
        guard !arrangedIndices.contains(index) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            arrangedIndices.append(index)
        }
    }

    func removeFromSequence(index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            arrangedIndices.removeAll { $0 == index }
        }
    }

    func resetSequence() {
        withAnimation { arrangedIndices = [] }
    }

    // MARK: Submission

    func submitAnswer(progressVM: GameProgressViewModel) {
        guard let quest = currentQuest else { return }

        stopTimer()

        switch quest.mechanic {
        case .multipleChoice, .sqlBuilder, .reverseEngineer:
            guard let answer = selectedToken else { return }
            isCorrect = (answer == quest.correctJoin)

        case .sequenceOrder:
            isCorrect = sequenceIsCorrect
        }

        questsAttempted += 1

        if isCorrect {
            let fast = timeRemaining > (quest.difficulty.timeLimit * 0.5)
            let xp   = progressVM.awardXP(hintsUsed: hintsUsed, answeredFast: fast)
            xpEarned      = xp
            sessionXP    += xp
            questsCorrect += 1
            progressVM.markCompleted(quest)
        } else {
            xpEarned = 0
            progressVM.penalizeWrongAnswer()
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            currentPhase = .feedback
        }
    }

    var canSubmit: Bool {
        guard let quest = currentQuest else { return false }
        switch quest.mechanic {
        case .multipleChoice, .sqlBuilder, .reverseEngineer: return selectedToken != nil
        case .sequenceOrder: return arrangedIndices.count == (quest.sqlClauses?.count ?? 0)
        }
    }

    func nextQuest(progressVM: GameProgressViewModel) {
        let next = currentQuestIndex + 1
        if next < quests.count {
            startQuest(at: next)
        } else {
            withAnimation { currentPhase = .summary }
        }
    }

    func returnToHub() {
        stopTimer()
        sessionXP       = 0
        questsAttempted = 0
        questsCorrect   = 0
        withAnimation { currentPhase = .hub }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else { break }
                self.timeRemaining = max(0, self.timeRemaining - 0.1)
            }
            if !Task.isCancelled && self.timeRemaining <= 0 && self.currentPhase == .challenge {
                self.handleTimeout()
            }
        }
    }

    private func handleTimeout() {
        guard currentPhase == .challenge else { return }
        isCorrect       = false
        xpEarned        = 0
        questsAttempted += 1
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            currentPhase = .feedback
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}
