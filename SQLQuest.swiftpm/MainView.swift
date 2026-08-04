import SwiftUI

// MARK: - MainView (Adaptive Root)
// iPad (regular width) → NavigationSplitView with sidebar
// iPhone (compact width) → TabView

struct MainView: View {
    @StateObject private var joinVM    = JoinViewModel()
    @StateObject private var multiVM   = MultiTableViewModel()
    @StateObject private var aiVM      = AITutorViewModel()

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            iPadRootView(joinVM: joinVM, multiVM: multiVM, aiVM: aiVM)
        } else {
            iPhoneRootView(joinVM: joinVM, multiVM: multiVM, aiVM: aiVM)
        }
    }
}

// MARK: - iPad Root (NavigationSplitView)

struct iPadRootView: View {
    @ObservedObject var joinVM  : JoinViewModel
    @ObservedObject var multiVM : MultiTableViewModel
    @ObservedObject var aiVM    : AITutorViewModel

    @State private var selectedSection: AppSection? = .exploration
    @State private var lastFailedQuest: Quest?       = nil

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.rawValue).font(.body.weight(.medium))
                        Text(section.subtitle).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                } icon: {
                    Image(systemName: section.icon).foregroundColor(section.color)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("SQLQuest")
            .listStyle(.sidebar)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection ?? .exploration {
        case .exploration:
            ExplorationView(viewModel: joinVM)
        case .advanced:
            AdvancedExplorationView(viewModel: multiVM)
        case .quest:
            QuestView(onQuestFailed: { quest in
                lastFailedQuest = quest
                // Switch to AI tab and inject context
                aiVM.context.lastFailedQuest = quest
                selectedSection = .ai
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    aiVM.explainFailedQuest(quest)
                }
            })
        case .ai:
            AITutorView(context: AIContext(
                activeJoin: joinVM.selectedJoin,
                lastFailedQuest: lastFailedQuest,
                activeTab: selectedSection ?? .ai
            ))
        }
    }
}

// MARK: - iPhone Root (TabView)

struct iPhoneRootView: View {
    @ObservedObject var joinVM  : JoinViewModel
    @ObservedObject var multiVM : MultiTableViewModel
    @ObservedObject var aiVM    : AITutorViewModel

    var body: some View {
        TabView {
            NavigationStack { ExplorationView(viewModel: joinVM) }
                .tabItem { Label("Explore", systemImage: AppSection.exploration.icon) }

            NavigationStack { AdvancedExplorationView(viewModel: multiVM) }
                .tabItem { Label("3-Table", systemImage: AppSection.advanced.icon) }

            NavigationStack { QuestView() }
                .tabItem { Label("Quests", systemImage: AppSection.quest.icon) }

            NavigationStack { AITutorView() }
                .tabItem { Label("AI Tutor", systemImage: AppSection.ai.icon) }
        }
    }
}

// MARK: - Exploration View (2-Table)

struct ExplorationView: View {
    @ObservedObject var viewModel: JoinViewModel
    @State private var showRawData  = false
    @State private var aiInputText  = ""

    var body: some View {
        ScrollView {
            // Wider, more breathable layout
            VStack(alignment: .leading, spacing: 28) {

                // ── Header ───────────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("SQL Join Visualizer")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading, endPoint: .trailing))

                    Text("Select a JOIN type to see how two tables combine.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        showRawData = true
                    } label: {
                        Label("Inspect Source Tables", systemImage: "tablecells")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(22)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
                .padding(.horizontal, 32)

                // ── JOIN Selector ─────────────────────────────────────────────
                JoinSelectorView(selectedJoin: $viewModel.selectedJoin)

                // ── What this JOIN means ──────────────────────────────────────
                Text(viewModel.selectedJoin.sqlDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .transition(.opacity)
                    .animation(.easeInOut, value: viewModel.selectedJoin)

                // ── Venn Diagram + Particle Flow ──────────────────────────────
                ZStack {
                    VennDiagramView(selectedJoin: viewModel.selectedJoin)

                    DataFlowOverlay(joinType: viewModel.selectedJoin)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(viewModel.vennAccessibilityDescription)

                // ── Result Table ──────────────────────────────────────────────
                resultSection

                // ── Live SQL ──────────────────────────────────────────────────
                sqlSection

                // ── NLP Input ─────────────────────────────────────────────────
                nlpSection
                    .padding(.bottom, 32)
            }
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationTitle("Explore Joins")
        .sheet(isPresented: $showRawData) {
            RawDataView(viewModel: viewModel)
        }
    }

    // MARK: Result Table

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Query Result")
                    .font(.title3.bold())
                Spacer()
                Text("\(viewModel.joinResults.count) row\(viewModel.joinResults.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Table header
            HStack {
                Text("ID").font(.caption.weight(.bold)).foregroundColor(.secondary).frame(width: 32)
                Text("Student Name").font(.caption.weight(.bold)).foregroundColor(.secondary)
                Spacer()
                Text("Club").font(.caption.weight(.bold)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)

            LazyVStack(spacing: 8) {
                ForEach(viewModel.joinResults) { row in
                    ResultRow(result: row)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.94).combined(with: .opacity),
                            removal:   .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.joinResults.count)
        }
        .padding(.horizontal, 28)
    }

    // MARK: SQL Preview

    private var sqlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live SQL")
                .font(.title3.bold())

            SQLHighlightView(joinType: viewModel.selectedJoin)
        }
        .padding(.horizontal, 28)
    }

    // MARK: NLP Input

    private var nlpSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Describe what data you need", systemImage: "waveform.and.mic")
                .font(.title3.bold())
            Text("Type a plain-English description and the visualizer will select the matching JOIN.")
                .font(.subheadline).foregroundColor(.secondary)

            HStack(spacing: 10) {
                TextField("e.g. 'show all students, even without a club'", text: $aiInputText)
                    .font(.body)
                    .padding(14)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
                    .onSubmit { submitNLP() }

                Button(action: submitNLP) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(14)
                        .background(aiInputText.isEmpty ? Color.secondary : Color.blue)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(aiInputText.isEmpty)
            }
        }
        .padding(.horizontal, 28)
    }

    private func submitNLP() {
        guard !aiInputText.isEmpty else { return }
        viewModel.processNaturalLanguage(query: aiInputText)
        aiInputText = ""
    }
}

// MARK: - Result Row

struct ResultRow: View {
    let result: JoinedResult

    var body: some View {
        HStack(spacing: 14) {
            Text(result.studentId)
                .font(DS.Font.codeXs)
                .foregroundColor(result.studentId == "NULL" ? .red : .secondary)
                .frame(width: 32, alignment: .center)

            Text(result.studentName)
                .font(.body.weight(.semibold))
                .foregroundColor(result.studentName == "NULL" ? .red : .primary)

            Spacer()

            Text(result.clubName)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(result.clubName == "NULL" ? .red : .green)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(result.clubName == "NULL" ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 5, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Row: ID \(result.studentId), \(result.studentName), club: \(result.clubName)")
    }
}

// MARK: - SQL Highlight View

struct SQLHighlightView: View {
    let joinType: JoinType

    private let kw   = Color(red: 0.35, green: 0.78, blue: 1.0)
    private let tbl  = Color(red: 1.0,  green: 0.85, blue: 0.4)
    private let punc = Color(red: 0.6,  green: 0.9,  blue: 0.65)
    private let sel  = Color(red: 0.95, green: 0.55, blue: 0.3)

    var joinColor: Color { joinType.color.opacity(0.9) }

    var joinKeyword: String { joinType.rawValue }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            (Text("SELECT ").foregroundColor(kw).bold()
             + Text("* ").foregroundColor(sel)
             + Text("FROM ").foregroundColor(kw).bold()
             + Text("Students").foregroundColor(tbl))

            (Text(joinKeyword + " ").foregroundColor(joinColor).bold()
             + Text("Clubs").foregroundColor(tbl))
            .animation(.easeInOut(duration: 0.2), value: joinKeyword)

            (Text("ON ").foregroundColor(kw).bold()
             + Text("Students").foregroundColor(tbl)
             + Text(".id ").foregroundColor(punc)
             + Text("= ").foregroundColor(.white.opacity(0.5))
             + Text("Clubs").foregroundColor(tbl)
             + Text(".id;").foregroundColor(punc))
        }
        .font(DS.Font.code)
        .lineSpacing(6)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .cornerRadius(14)
        .accessibilityLabel("SQL: SELECT * FROM Students \(joinKeyword) Clubs ON Students.id = Clubs.id")
    }
}

// MARK: - Advanced Exploration View (3-Table)

struct AdvancedExplorationView: View {
    @ObservedObject var viewModel: MultiTableViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("3-Table Join Explorer")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .leading, endPoint: .trailing))

                    Text("Explore how Students, Enrollments, and Courses join in a chain pipeline.")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.horizontal, 32)

                // 3-Way Venn
                ThreeWayVennView(joinAB: viewModel.joinAB, joinBC: viewModel.joinBC)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)

                // JOIN type selectors
                HStack(spacing: 20) {
                    MiniJoinSelector(label: "Students ↔ Enrollments", selected: $viewModel.joinAB)
                    MiniJoinSelector(label: "Enrollments ↔ Courses",  selected: $viewModel.joinBC)
                }
                .padding(.horizontal, 28)

                // SQL Preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Generated SQL").font(.title3.bold())
                    Text(viewModel.generatedSQL)
                        .font(DS.Font.code)
                        .lineSpacing(6)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
                        .foregroundColor(.green)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 28)

                // Insight text
                Text(viewModel.insightText)
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding(.horizontal, 28)
                    .animation(.easeInOut, value: viewModel.insightText)

                // Dynamic Result Table
                dynamicResultTable
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
            }
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationTitle("3-Table Joins")
    }

    private var dynamicResultTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Query Result")
                    .font(.title3.bold())
                Spacer()
                Text("\(viewModel.joinResults.count) rows")
                    .font(.subheadline).foregroundColor(.secondary)
            }

            let cols = viewModel.joinResults.first?.columns ?? []
            if !cols.isEmpty {
                // Column header
                HStack(spacing: 8) {
                    ForEach(cols, id: \.self) { col in
                        Text(col.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)

                LazyVStack(spacing: 8) {
                    ForEach(viewModel.joinResults) { row in
                        HStack(spacing: 8) {
                            ForEach(row.columns, id: \.self) { col in
                                let val = row.values[col] ?? "NULL"
                                Text(val)
                                    .font(.subheadline)
                                    .foregroundColor(val == "NULL" ? .red : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.04), radius: 4)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.joinResults.count)
            } else {
                Text("No results for current JOIN configuration.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}
