import SwiftUI

// MARK: - QuestView Entry Point

struct QuestView: View {
    @StateObject private var questVM    = QuestViewModel()
    @StateObject private var progressVM = GameProgressViewModel()

    // Passed up to MainView so AI tab gets context
    var onQuestFailed: ((Quest) -> Void)? = nil

    var body: some View {
        Group {
            switch questVM.currentPhase {
            case .hub:       QuestHubView(questVM: questVM, progressVM: progressVM)
            case .challenge: QuestChallengeView(questVM: questVM, progressVM: progressVM,
                                                onFailed: onQuestFailed)
            case .feedback:  QuestFeedbackView(questVM: questVM, progressVM: progressVM,
                                               onFailed: onQuestFailed)
            case .summary:   QuestSummaryView(questVM: questVM, progressVM: progressVM)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: questVM.currentPhase)
    }
}

// MARK: ─── QUEST HUB ─────────────────────────────────────────────────────────

struct QuestHubView: View {
    @ObservedObject var questVM    : QuestViewModel
    @ObservedObject var progressVM : GameProgressViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                // XP card
                XPProgressCard(progressVM: progressVM)
                    .padding(.horizontal)

                // Stats row
                HStack(spacing: 14) {
                    MiniStat(value: "\(progressVM.completedIDs.count)/\(questVM.quests.count)",
                             label: "Completed", icon: "checkmark.circle.fill", color: .green)
                    MiniStat(value: "\(progressVM.currentStreak)",
                             label: "Streak",    icon: "flame.fill",            color: .orange)
                    MiniStat(value: "\(progressVM.totalXP)",
                             label: "Total XP",  icon: "star.fill",             color: .purple)
                }
                .padding(.horizontal)

                // Sectioned quest list — no difficulty spoilers in card titles
                ForEach(questVM.quests.grouped(), id: \.0) { difficulty, group in
                    DifficultySection(
                        difficulty: difficulty,
                        quests: group,
                        progressVM: progressVM,
                        onSelect: { questVM.startQuest(at: questVM.quests.firstIndex(where: { $0.id == $0.id }) ?? 0) },
                        questVM: questVM
                    )
                }

                Button(role: .destructive) {
                    progressVM.resetProgress()
                } label: {
                    Label("Reset All Progress", systemImage: "arrow.counterclockwise")
                        .font(.caption).foregroundColor(.red.opacity(0.6))
                }
                .padding(.bottom, 16)
            }
            .padding(.top, 20)
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationTitle("Quest Mode")
    }
}

// MARK: - Difficulty Section

struct DifficultySection: View {
    let difficulty : QuestDifficulty
    let quests     : [Quest]
    @ObservedObject var progressVM: GameProgressViewModel
    let onSelect   : () -> Void
    @ObservedObject var questVM: QuestViewModel

    @State private var isExpanded = true

    var completedCount: Int { quests.filter { progressVM.isCompleted($0) }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Button {
                withAnimation(.spring(response: 0.35)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: difficulty.icon)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(difficulty.color)

                    Text(difficulty.rawValue.uppercased())
                        .font(.caption.weight(.heavy))
                        .foregroundColor(difficulty.color)
                        .tracking(1.5)

                    Spacer()

                    Text("\(completedCount)/\(quests.count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(completedCount == quests.count ? .green : .secondary)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            if isExpanded {
                // Horizontal scroll of quest cards in this section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(quests) { quest in
                            QuestCard(
                                quest: quest,
                                isCompleted: progressVM.isCompleted(quest),
                                action: {
                                    if let i = questVM.quests.firstIndex(where: { $0.id == quest.id }) {
                                        questVM.startQuest(at: i)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Quest Card (NO SPOILERS)

struct QuestCard: View {
    let quest      : Quest
    let isCompleted: Bool
    let action     : () -> Void

    var mechanicIcon: String {
        switch quest.mechanic {
        case .multipleChoice:  return "list.bullet.circle"
        case .sqlBuilder:      return "keyboard"
        case .reverseEngineer: return "eye.slash"
        case .sequenceOrder:   return "arrow.up.arrow.down.circle"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Top row: mechanic badge + completion mark
                HStack {
                    Image(systemName: mechanicIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(quest.difficulty.color)
                    Text(quest.mechanic.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(quest.difficulty.color)
                    Spacer()
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompleted ? .green : Color(.systemGray4))
                        .font(.callout)
                }

                // Intriguing title — deliberately no JOIN name
                Text(quest.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                // Bottom: difficulty badge + locked hint
                HStack {
                    Text(isCompleted ? "✓ Solved" : "Start →")
                        .font(.caption.weight(.bold))
                        .foregroundColor(isCompleted ? .green : quest.difficulty.color)
                    Spacer()
                    // Time limit hint
                    Label("\(Int(quest.difficulty.timeLimit))s", systemImage: "timer")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(width: 190, height: 144)
            .background(Color(.systemBackground))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isCompleted ? Color.green.opacity(0.4) : quest.difficulty.color.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quest: \(quest.title). \(isCompleted ? "Completed." : "Not yet solved.")")
        .accessibilityHint(isCompleted ? "Tap to replay." : "Tap to start the challenge.")
    }
}

// MARK: ─── CHALLENGE VIEW ─────────────────────────────────────────────────────

struct QuestChallengeView: View {
    @ObservedObject var questVM    : QuestViewModel
    @ObservedObject var progressVM : GameProgressViewModel
    var onFailed: ((Quest) -> Void)?

    var quest: Quest? { questVM.currentQuest }

    var timerProgress: Double { questVM.timeRemaining / (quest?.difficulty.timeLimit ?? 45) }
    var timerColor: Color {
        switch timerProgress {
        case 0.5...: return .green
        case 0.25...: return .orange
        default: return .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                challengeHeader
                    .padding(.horizontal)

                if let quest {
                    // Scenario card
                    ScenarioBanner(quest: quest, showHint: questVM.showHint)

                    // Mechanic-specific interaction area
                    Group {
                        switch quest.mechanic {
                        case .multipleChoice:
                            MultipleChoiceArea(questVM: questVM)

                        case .sqlBuilder:
                            SQLBuilderArea(questVM: questVM, quest: quest)

                        case .reverseEngineer:
                            ReverseEngineerArea(questVM: questVM, quest: quest)

                        case .sequenceOrder:
                            SequenceOrderArea(questVM: questVM, quest: quest)
                        }
                    }
                    .padding(.horizontal)

                    // Hint button
                    if !questVM.showHint {
                        Button(action: { questVM.revealHint() }) {
                            Label("Show Hint  (−20 XP)", systemImage: "lightbulb.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.orange)
                                .padding(.vertical, 10).padding(.horizontal, 18)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(22)
                        }
                        .buttonStyle(.plain)
                    }

                    // Submit button
                    Button {
                        questVM.submitAnswer(progressVM: progressVM)
                    } label: {
                        Text(questVM.canSubmit ? "Submit Answer" : "Make a selection first…")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(questVM.canSubmit ? Color.blue : Color(.systemGray4))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .disabled(!questVM.canSubmit)
                    .padding(.horizontal)
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Exit") { questVM.returnToHub() }.foregroundColor(.red)
            }
            ToolbarItem(placement: .principal) {
                Text("Quest \(questVM.currentQuestIndex + 1) of \(questVM.quests.count)")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private var challengeHeader: some View {
        VStack(spacing: 8) {
            HStack {
                // Dot progress
                HStack(spacing: 5) {
                    ForEach(0..<min(questVM.quests.count, 13), id: \.self) { i in
                        Circle()
                            .fill(i == questVM.currentQuestIndex ? Color.blue : (i < questVM.currentQuestIndex ? Color.green : Color(.systemGray4)))
                            .frame(width: 7, height: 7)
                            .scaleEffect(i == questVM.currentQuestIndex ? 1.4 : 1.0)
                            .animation(.spring(), value: questVM.currentQuestIndex)
                    }
                }
                Spacer()
                Label(String(format: "%.0fs", questVM.timeRemaining), systemImage: "timer")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(timerColor)
                    .monospacedDigit()
                    .animation(.easeInOut, value: timerColor)
            }
            // Timer bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5)).frame(height: 5)
                    Capsule().fill(timerColor).frame(width: geo.size.width * timerProgress, height: 5)
                        .animation(.linear(duration: 0.1), value: timerProgress)
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Scenario Banner

struct ScenarioBanner: View {
    let quest   : Quest
    let showHint: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: quest.difficulty.icon)
                    .foregroundColor(quest.difficulty.color)
                Text(quest.difficulty.rawValue.uppercased())
                    .font(.caption.weight(.heavy))
                    .foregroundColor(quest.difficulty.color)
                    .tracking(1)
                Spacer()
                Text(quest.mechanic.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            Text(quest.title)
                .font(.title3.bold())

            Text(quest.scenario)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if showHint {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill").foregroundColor(.orange).font(.callout)
                    Text(quest.hint)
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scenario: \(quest.title). \(quest.scenario)")
    }
}

// MARK: ─── MECHANIC VIEWS ─────────────────────────────────────────────────────

// 1. Multiple Choice
struct MultipleChoiceArea: View {
    @ObservedObject var questVM: QuestViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select the correct JOIN type:")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                ForEach(JoinType.allCases, id: \.self) { type in
                    JoinChoiceButton(type: type,
                                     isSelected: questVM.selectedToken == type,
                                     action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                            questVM.selectedToken = type
                        }
                    })
                }
            }
        }
    }
}

struct JoinChoiceButton: View {
    let type      : JoinType
    let isSelected: Bool
    let action    : () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.title2).symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? type.color : .secondary)
                Text(type.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isSelected ? type.color : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? type.color.opacity(0.14) : Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? type.color : Color(.systemGray4),
                        lineWidth: isSelected ? 2 : 1))
            .shadow(color: isSelected ? type.color.opacity(0.28) : .clear, radius: 8)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.65), value: isSelected)
        .accessibilityLabel(type.rawValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// 2. SQL Builder (tap token → fills blank in the SQL preview)
struct SQLBuilderArea: View {
    @ObservedObject var questVM: QuestViewModel
    let quest: Quest

    var joinText  : String { questVM.selectedToken?.rawValue ?? "[ ________ ]" }
    var joinColor : Color  { questVM.selectedToken?.color ?? .secondary.opacity(0.5) }

    // Terminal theme colours
    private let kw   = Color(red: 0.35, green: 0.78, blue: 1.0)
    private let tbl  = Color(red: 1.0,  green: 0.85, blue: 0.4)
    private let punc = Color(red: 0.6,  green: 0.9,  blue: 0.65)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // SQL preview with blank
            VStack(alignment: .leading, spacing: 5) {
                Label("SQL Preview", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.caption.weight(.semibold)).foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    (Text("SELECT ").foregroundColor(kw).bold()
                     + Text("* ").foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.4))
                     + Text("FROM ").foregroundColor(kw).bold()
                     + Text("Students").foregroundColor(tbl))

                    (Text(joinText + " ").foregroundColor(joinColor).bold()
                     + Text("Clubs").foregroundColor(tbl))
                    .animation(.spring(response: 0.3), value: questVM.selectedToken)

                    (Text("ON ").foregroundColor(kw).bold()
                     + Text("Students").foregroundColor(tbl)
                     + Text(".id ").foregroundColor(punc)
                     + Text("= ").foregroundColor(.white.opacity(0.5))
                     + Text("Clubs").foregroundColor(tbl)
                     + Text(".id;").foregroundColor(punc))
                }
                .font(.system(.subheadline, design: .monospaced))
                .lineSpacing(5)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.08, green: 0.08, blue: 0.12))
                .cornerRadius(12)
            }

            // Token picker
            Text("Tap the correct JOIN keyword to fill the blank:")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                ForEach(JoinType.allCases, id: \.self) { type in
                    JoinChoiceButton(type: type,
                                     isSelected: questVM.selectedToken == type,
                                     action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                            questVM.selectedToken = type
                        }
                    })
                }
            }
        }
    }
}

// 3. Reverse Engineer — show result table, identify JOIN
struct ReverseEngineerArea: View {
    @ObservedObject var questVM: QuestViewModel
    let quest: Quest

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Query Result (analyze this table)", systemImage: "tablecells.fill")
                .font(.subheadline.weight(.semibold))

            // Snapshot result table
            if let snapshot = quest.resultSnapshot {
                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("ID").font(.caption.weight(.bold)).foregroundColor(.secondary).frame(width: 36)
                        Text("Student Name").font(.caption.weight(.bold)).foregroundColor(.secondary)
                        Spacer()
                        Text("Club").font(.caption.weight(.bold)).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color(.systemGray6))

                    Divider()

                    ForEach(snapshot) { row in
                        HStack {
                            Text(row.studentId)
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundColor(row.studentId == "NULL" ? .red : .secondary)
                                .frame(width: 36)
                            Text(row.studentName)
                                .font(.subheadline)
                                .foregroundColor(row.studentName == "NULL" ? .red : .primary)
                            Spacer()
                            Text(row.clubName)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(row.clubName == "NULL" ? .red : .green)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(row.clubName == "NULL" ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 9)

                        if snapshot.last?.id != row.id { Divider() }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 6)
            }

            Text("Which JOIN type produced this result?")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                ForEach(JoinType.allCases, id: \.self) { type in
                    JoinChoiceButton(type: type,
                                     isSelected: questVM.selectedToken == type,
                                     action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                            questVM.selectedToken = type
                        }
                    })
                }
            }
        }
    }
}

// 4. Sequence Order — tap clauses to arrange SQL in order
struct SequenceOrderArea: View {
    @ObservedObject var questVM: QuestViewModel
    let quest: Quest

    var clauses: [String] { quest.sqlClauses ?? [] }
    var placedCount: Int  { questVM.arrangedIndices.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tap the SQL clauses in the correct order:")
                .font(.subheadline.weight(.semibold))

            // Assembled query preview
            VStack(alignment: .leading, spacing: 5) {
                Label("Assembling Query", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.caption.weight(.semibold)).foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(questVM.arrangedIndices, id: \.self) { idx in
                        Text(clauses[idx])
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    if placedCount < clauses.count {
                        Text("[ tap a clause below to place it here ]")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                .background(Color(red: 0.08, green: 0.08, blue: 0.12))
                .cornerRadius(12)
            }

            // Clause tokens (greyed out once placed)
            Text("Available clauses:")
                .font(.caption.weight(.semibold)).foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(clauses.enumerated()), id: \.offset) { idx, clause in
                    let placed = questVM.arrangedIndices.contains(idx)
                    Button {
                        if placed {
                            questVM.removeFromSequence(index: idx)
                        } else {
                            questVM.appendToSequence(index: idx)
                        }
                    } label: {
                        Text(clause)
                            .font(.system(.caption, design: .monospaced).weight(.semibold))
                            .foregroundColor(placed ? .secondary : .primary)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(placed ? Color(.systemGray5) : Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(placed ? Color.clear : Color(.systemGray4), lineWidth: 1))
                            .overlay(
                                placed
                                    ? Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                        .padding(6)
                                    : nil
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25), value: placed)
                }
            }

            if placedCount > 0 {
                Button { questVM.resetSequence() } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: ─── FEEDBACK VIEW ─────────────────────────────────────────────────────

struct QuestFeedbackView: View {
    @ObservedObject var questVM    : QuestViewModel
    @ObservedObject var progressVM : GameProgressViewModel
    var onFailed: ((Quest) -> Void)?

    @State private var ringScale: CGFloat = 0.3
    @State private var iconScale: CGFloat = 0.3
    @State private var xpFloat  : CGFloat = 0
    @State private var xpOpacity: Double  = 1

    var isCorrect: Bool    { questVM.isCorrect }
    var fColor: Color      { isCorrect ? .green : .red }
    var quest: Quest?      { questVM.currentQuest }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 32)

                // Result icon
                ZStack {
                    Circle().fill(fColor.opacity(0.12)).frame(width: 160, height: 160).scaleEffect(ringScale)
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 76)).foregroundColor(fColor)
                        .scaleEffect(iconScale).shadow(color: fColor.opacity(0.35), radius: 18)
                }

                Text(isCorrect ? "Correct!" : "Not Quite")
                    .font(.title.bold()).foregroundColor(fColor)

                // XP earned
                if isCorrect && questVM.xpEarned > 0 {
                    Text("+\(questVM.xpEarned) XP\(progressVM.currentStreak > 1 ? "  x\(progressVM.currentStreak) streak" : "")")
                        .font(.headline.bold()).foregroundColor(.purple)
                        .offset(y: xpFloat).opacity(xpOpacity)
                }

                // Explanation card
                if let quest {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(isCorrect ? "Why it's correct:" : "The right answer: \(quest.correctJoin.rawValue)",
                              systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(isCorrect ? .green : .orange)

                        Text(quest.explanation)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        // AI tutor CTA on failure
                        if !isCorrect {
                            Divider()
                            Button {
                                onFailed?(quest)
                            } label: {
                                Label("Ask AI Tutor to explain", systemImage: "sparkles")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.purple)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.05), radius: 8)
                    .padding(.horizontal)
                }

                // Navigation
                VStack(spacing: 12) {
                    let hasNext = questVM.currentQuestIndex + 1 < questVM.quests.count
                    Button {
                        if hasNext { questVM.nextQuest(progressVM: progressVM) }
                        else       { withAnimation { questVM.currentPhase = .summary } }
                    } label: {
                        Text(hasNext ? "Next Quest" : "View Results")
                            .font(.headline.bold()).frame(maxWidth: .infinity).padding()
                            .background(isCorrect ? Color.blue : Color.orange)
                            .foregroundColor(.white).cornerRadius(16)
                    }
                    .padding(.horizontal).buttonStyle(.plain)

                    Button { questVM.returnToHub() } label: {
                        Text("Back to Hub").font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.52)) {
                ringScale = 1.0; iconScale = 1.0
            }
            if isCorrect {
                withAnimation(.easeOut(duration: 0.85).delay(0.3)) { xpFloat = -42 }
                withAnimation(.easeIn(duration: 0.4).delay(0.8))   { xpOpacity = 0 }
            }
        }
    }
}

// MARK: ─── SUMMARY VIEW ──────────────────────────────────────────────────────

struct QuestSummaryView: View {
    @ObservedObject var questVM    : QuestViewModel
    @ObservedObject var progressVM : GameProgressViewModel

    var msg: String {
        switch questVM.accuracy {
        case 100:   return "Flawless! Perfect score."
        case 70...: return "Great work! Keep polishing those skills "
        default:    return "Every mistake is a lesson. Keep going."
        }
    }

    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                Spacer(minLength: 24)
                Text("Session Complete!").font(.largeTitle.bold())
                Text(msg).font(.headline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)

                LazyVGrid(columns: cols, spacing: 14) {
                    SummaryStatCard(title: "Correct",   value: "\(questVM.questsCorrect)/\(questVM.questsAttempted)", color: .green,  icon: "checkmark.circle.fill")
                    SummaryStatCard(title: "Accuracy",  value: "\(questVM.accuracy)%",  color: .blue,   icon: "target")
                    SummaryStatCard(title: "XP Earned", value: "+\(questVM.sessionXP)", color: .purple, icon: "star.fill")
                    SummaryStatCard(title: "Streak",    value: "\(progressVM.currentStreak)", color: .orange, icon: "flame.fill")
                }
                .padding(.horizontal)

                XPProgressCard(progressVM: progressVM).padding(.horizontal)

                Button { questVM.returnToHub() } label: {
                    Text("Back to Quest Hub")
                        .font(.headline.bold()).frame(maxWidth: .infinity).padding()
                        .background(Color.blue).foregroundColor(.white).cornerRadius(16)
                }
                .padding(.horizontal).buttonStyle(.plain).padding(.bottom, 32)
            }
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: ─── SHARED COMPONENTS ─────────────────────────────────────────────────

struct XPProgressCard: View {
    @ObservedObject var progressVM: GameProgressViewModel

    var body: some View {
        VStack(spacing: DS.Space.sm + 2) {
            HStack(spacing: DS.Space.sm) {
                // Level icon — SF Symbol from LevelInfo, no emoji
                Image(systemName: progressVM.levelInfo.icon)
                    .font(.title2)
                    .foregroundColor(progressVM.levelColor)
                    .frame(width: 36, height: 36)
                    .background(progressVM.levelColor.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(progressVM.level)
                        .font(DS.Font.groupHeader)
                        .foregroundColor(progressVM.levelColor)
                    Text("\(progressVM.totalXP) XP total")
                        .font(DS.Font.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                // Streak counter using SF Symbol
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(DS.Font.subhead)
                    Text("\(progressVM.currentStreak)")
                        .font(DS.Font.bodyBold)
                        .foregroundColor(.orange)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5)).frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [progressVM.levelColor.opacity(0.7), progressVM.levelColor],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progressVM.levelProgress, height: 8)
                        .animation(.spring(response: 0.6), value: progressVM.levelProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(DS.Space.md)
        .background(Color(.systemBackground))
        .cornerRadius(DS.Radius.lg)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

struct MiniStat: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color).font(.caption)
            Text(value).font(.subheadline.bold())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color(.systemBackground)).cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 5)
    }
}

struct SummaryStatCard: View {
    let title: String; let value: String; let color: Color; let icon: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(16)
        .background(Color(.systemBackground)).cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6)
    }
}
