import SwiftUI

// MARK: - AITutorView
// The AI Tutor is a first-class tab in SQLQuest, not an afterthought.
// Layout: suggestion chips when empty → conversation bubbles → text input.
// API key is stored in memory only (not persisted for security).
// When no key is set, the app runs in simulation mode automatically.

struct AITutorView: View {
    @StateObject private var vm      = AITutorViewModel()
    @FocusState  private var focused : Bool

    // Injected from parent so the AI knows what the user is doing elsewhere
    var context: AIContext = AIContext()

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            aiHeader

            Divider()

            // Main content
            if vm.messages.isEmpty {
                welcomeScreen
            } else {
                conversationFeed
            }

            Divider()

            // Input dock
            inputDock
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear { vm.context = context }
        .onChange(of: context.activeJoin) { vm.context.activeJoin = $0 }
        .onChange(of: context.lastFailedQuest?.id) { _ in vm.context.lastFailedQuest = context.lastFailedQuest }
        .sheet(isPresented: $vm.showKeyEntry) { apiKeySheet }
    }

    // MARK: - Header

    private var aiHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple.opacity(0.8), .blue.opacity(0.6)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("SQLQuest AI")
                    .font(.headline.bold())
                Text(vm.apiKey.isEmpty ? "Simulation Mode" : "Claude-Powered")
                    .font(.caption)
                    .foregroundColor(vm.apiKey.isEmpty ? .orange : .green)
            }

            Spacer()

            // Context badge
            if let join = context.activeJoin {
                Text(join.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(join.color)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(join.color.opacity(0.12))
                    .cornerRadius(8)
            }

            // API Key button
            Button {
                vm.showKeyEntry = true
            } label: {
                Image(systemName: vm.apiKey.isEmpty ? "key.slash" : "key.fill")
                    .font(.caption)
                    .foregroundColor(vm.apiKey.isEmpty ? .secondary : .green)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .help("Configure Anthropic API Key")

            // Clear chat
            if !vm.messages.isEmpty {
                Button {
                    withAnimation { vm.messages = [] }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Welcome / Empty State

    private var welcomeScreen: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Hero badge
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.purple.opacity(0.2), .blue.opacity(0.15)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                        Image(systemName: "sparkles")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .blue],
                                               startPoint: .top, endPoint: .bottom))
                    }

                    Text("Your SQL Tutor")
                        .font(.title2.bold())

                    Text(vm.apiKey.isEmpty
                        ? "Running in simulation mode. Add a Claude API key for full AI responses."
                        : "Powered by Claude. Ask me anything about SQL JOINs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 30)

                // Suggestion chips in a 2-column grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(vm.suggestions, id: \.label) { s in
                        SuggestionChip(icon: s.icon, label: s.label) {
                            vm.sendSuggestion(s.prompt)
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Context-aware actions (shown when relevant context exists)
                if context.lastFailedQuest != nil || context.activeJoin != nil {
                    contextActionBanner
                }

                Spacer(minLength: 20)
            }
        }
    }

    private var contextActionBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Context Actions")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            if let quest = context.lastFailedQuest {
                ContextActionButton(
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    title: "Why did I fail?",
                    subtitle: "'\(quest.title)'"
                ) { vm.explainFailedQuest(quest) }
            }

            ContextActionButton(
                icon: "wand.and.stars",
                color: .purple,
                title: "Generate a custom scenario",
                subtitle: "Practice with an AI-crafted problem"
            ) { vm.generateCustomScenario() }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Conversation Feed

    private var conversationFeed: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(vm.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id.uuidString)
                            .transition(.asymmetric(
                                insertion: .move(edge: msg.role == "user" ? .trailing : .leading).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    if vm.isLoading {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(20)
            }
            .onChange(of: vm.messages.count) { _ in
                withAnimation {
                    proxy.scrollTo(vm.isLoading ? "typing" : vm.messages.last?.id.uuidString)
                }
            }
            .onChange(of: vm.isLoading) { loading in
                if loading { withAnimation { proxy.scrollTo("typing") } }
            }
        }
    }

    // MARK: - Input Dock (premium redesign)
    // Uses Material.regular as the dock background, a gradient-outlined text field,
    // and a gradient send button — no emoji, all native SF Symbols.

    private var inputDock: some View {
        VStack(spacing: 0) {
            // Hairline separator with gradient fade
            LinearGradient(
                colors: [.clear, Color(.systemGray4).opacity(0.6), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 1)

            HStack(alignment: .bottom, spacing: DS.Space.sm + 2) {

                // ── Text field ────────────────────────────────────────────────
                ZStack(alignment: .leading) {
                    // Placeholder
                    if vm.inputText.isEmpty {
                        Text("Ask about SQL JOINs…")
                            .font(DS.Font.body)
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, DS.Space.md)
                            .padding(.vertical, DS.Space.sm + 4)
                            .allowsHitTesting(false)
                    }

                    TextField("", text: $vm.inputText, axis: .vertical)
                        .font(DS.Font.body)
                        .lineLimit(1...5)
                        .padding(.horizontal, DS.Space.md)
                        .padding(.vertical, DS.Space.sm + 4)
                        .focused($focused)
                        .onSubmit { if !vm.isLoading && !vm.inputText.isEmpty { vm.send() } }
                }
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.xl)
                        .fill(.regularMaterial)
                )
                .overlay(
                    // Gradient border — glows purple when focused, subtle otherwise
                    RoundedRectangle(cornerRadius: DS.Radius.xl)
                        .stroke(
                            LinearGradient(
                                colors: focused
                                    ? [Color.purple.opacity(0.8), Color.blue.opacity(0.5)]
                                    : [Color(.systemGray4), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: focused ? 1.5 : 1
                        )
                )
                .shadow(
                    color: focused ? Color.purple.opacity(0.18) : .clear,
                    radius: 10
                )
                .animation(.easeInOut(duration: 0.22), value: focused)

                // ── Send button ───────────────────────────────────────────────
                Button {
                    focused = false
                    vm.send()
                } label: {
                    Group {
                        if vm.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.body.weight(.bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        Group {
                            if vm.isLoading || vm.inputText.isEmpty {
                                Color(.systemGray4)
                                    .clipShape(Circle())
                            } else {
                                LinearGradient(
                                    colors: [Color.purple, Color.blue.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.purple.opacity(0.45), radius: 8, y: 3)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading || vm.inputText.isEmpty)
                .animation(.easeInOut(duration: 0.20), value: vm.inputText.isEmpty)
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.top, DS.Space.sm + 4)
            .padding(.bottom, DS.Space.md)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - API Key Sheet

    private var apiKeySheet: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-…", text: $vm.apiKey)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Anthropic API Key")
                } footer: {
                    Text("Your key is stored only in memory for this session. Get a key at console.anthropic.com. Without a key, SQLQuest AI runs in simulation mode.")
                        .font(.caption)
                }

                Section {
                    Button("Use Simulation Mode") {
                        vm.apiKey = ""
                        vm.showKeyEntry = false
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("AI Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { vm.showKeyEntry = false }
                        .font(.body.weight(.semibold))
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.purple.opacity(0.8), .blue.opacity(0.7)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            Text(message.content)
                .font(.body)
                .foregroundColor(isUser ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isUser {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.purple)
                        } else if message.isError {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.red.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.red.opacity(0.3)))
                        } else {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                        }
                    }
                )
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer(minLength: 60) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : "AI Tutor"): \(message.content)")
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase: Double = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple.opacity(0.8), .blue.opacity(0.7)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 7, height: 7)
                        .offset(y: sin(phase + Double(i) * 0.8) * -4)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.05), radius: 5)

            Spacer(minLength: 60)
        }
        .onAppear {
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let icon  : String
    let label : String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundColor(.purple)
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Context Action Button

struct ContextActionButton: View {
    let icon    : String
    let color   : Color
    let title   : String
    let subtitle: String
    let action  : () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(color.opacity(0.5))
            }
            .padding(14)
            .background(color.opacity(0.08))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
