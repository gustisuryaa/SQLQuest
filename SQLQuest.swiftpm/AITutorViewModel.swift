import SwiftUI

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id      = UUID()
    let role    : String   // "user" | "assistant"
    let content : String
    var isError : Bool = false
}

// MARK: - AI Context
// Passed from the rest of the app so the AI can give contextual advice.

struct AIContext {
    var activeJoin       : JoinType? = nil
    var lastFailedQuest  : Quest?    = nil
    var activeTab        : AppSection = .exploration
}

// MARK: - AITutorViewModel

@MainActor
final class AITutorViewModel: ObservableObject {

    @Published var messages   : [ChatMessage] = []
    @Published var inputText  : String = ""
    @Published var isLoading  : Bool   = false
    @Published var apiKey     : String = ""
    @Published var showKeyEntry: Bool  = false

    // Context injected from parent views
    var context: AIContext = AIContext()

    // MARK: - System Prompt

    private var systemPrompt: String {
        var ctx = ""
        if let join = context.activeJoin {
            ctx += " The user is currently exploring \(join.rawValue) in the Exploration tab."
        }
        if let quest = context.lastFailedQuest {
            ctx += " The user just failed the quest titled '\(quest.title)' which required a \(quest.correctJoin.rawValue). Their misconception likely involves: \(quest.hint)"
        }
        return """
        You are SQLQuest AI, an expert SQL tutor embedded inside a visual, gamified iOS learning app called SQLQuest.
        Your sole purpose is to teach SQL JOIN concepts clearly, concisely, and engagingly.
        \(ctx)

        Guidelines:
        - Keep responses SHORT (2-4 sentences max for simple questions, up to 8 for complex ones).
        - Use analogies and real-world metaphors to explain abstract JOIN behavior.
        - When relevant, embed a tiny SQL snippet inside backticks.
        - If the user failed a quest, proactively explain their misconception and guide them toward the right mental model.
        - If asked to generate a custom scenario, produce a SHORT real-world problem description + the ideal JOIN type with a one-line explanation.
        - Never reveal quest answers directly — guide with Socratic questions.
        - Be encouraging, not condescending. Treat the user as a capable beginner.
        """
    }

    // MARK: - Quick Prompt Suggestions (shown when chat is empty)

    let suggestions: [(icon: String, label: String, prompt: String)] = [
        ("lightbulb.fill",         "Explain INNER JOIN",  "Can you explain INNER JOIN using a real-world analogy?"),
        ("questionmark.circle",    "LEFT vs RIGHT",       "What's the actual difference between LEFT JOIN and RIGHT JOIN? When do I use each?"),
        ("tablecells.badge.ellipsis", "Generate a scenario", "Generate a custom real-world scenario where I need to choose the right JOIN type."),
        ("exclamationmark.triangle", "Why did I fail?",   "I just got a question wrong. Can you help me understand my mistake?"),
        ("list.bullet.clipboard",  "NULL explained",      "Why do NULL values appear in JOIN results? What do they mean?"),
        ("arrow.triangle.branch",  "3-way JOINs",        "How do 3-table JOINs work? Can you walk me through the logic step by step?")
    ]

    // MARK: - Send Message

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        let userMsg = ChatMessage(role: "user", content: text)
        messages.append(userMsg)

        isLoading = true
        Task {
            if apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
                let reply = simulateResponse(to: text)
                try? await Task.sleep(nanoseconds: 800_000_000)
                messages.append(ChatMessage(role: "assistant", content: reply))
            } else {
                await callAnthropicAPI(userMessage: text)
            }
            isLoading = false
        }
    }

    func sendSuggestion(_ prompt: String) {
        inputText = prompt
        send()
    }

    // MARK: - Context-Aware Quick Actions

    func explainFailedQuest(_ quest: Quest) {
        context.lastFailedQuest = quest
        let prompt = "I just failed the quest '\(quest.title)'. The correct answer was \(quest.correctJoin.rawValue) but I got it wrong. Can you explain why that was the right JOIN and what my likely misconception was?"
        inputText = prompt
        send()
    }

    func generateCustomScenario() {
        let prompt = "Generate a fresh, original real-world scenario where I need to decide between INNER JOIN, LEFT JOIN, or RIGHT JOIN. Don't reveal the answer — let me figure it out."
        inputText = prompt
        send()
    }

    // MARK: - Anthropic API Call

    private func callAnthropicAPI(userMessage: String) async {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,              forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",        forHTTPHeaderField: "anthropic-version")

        // Build conversation history (exclude error messages)
        let history = messages.dropLast().filter { !$0.isError }.map {
            ["role": $0.role, "content": $0.content]
        }

        let body: [String: Any] = [
            "model":      "claude-opus-4-6",
            "max_tokens": 512,
            "system":     systemPrompt,
            "messages":   history + [["role": "user", "content": userMessage]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let errBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                messages.append(ChatMessage(role: "assistant",
                    content: "API Error — check your key. Details: \(errBody)", isError: true))
                return
            }

            if let json       = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content    = json["content"] as? [[String: Any]],
               let firstBlock = content.first,
               let text       = firstBlock["text"] as? String {
                messages.append(ChatMessage(role: "assistant", content: text))
            }
        } catch {
            messages.append(ChatMessage(role: "assistant",
                content: "Network error: \(error.localizedDescription)", isError: true))
        }
    }

    // MARK: - Simulation Mode (no API key required)
    // Covers the most common SQL JOIN questions for SSC demo purposes.

    private func simulateResponse(to input: String) -> String {
        let q = input.lowercased()

        if q.contains("inner join") || q.contains("inner") && q.contains("analogy") {
            return "Think of INNER JOIN like a guest list for a VIP event. Only people whose names appear on BOTH the venue's list AND the organizer's list get in. Anyone on just one list gets turned away. In SQL: `SELECT * FROM A INNER JOIN B ON A.id = B.id` — only matched rows survive."
        }
        if q.contains("left") && q.contains("right") {
            return "LEFT JOIN says 'keep EVERYONE from the left table, bring in right-table data where it matches.' RIGHT JOIN says the opposite. The key insight: NULL values always appear on the OPTIONAL side. Left JOIN → NULLs in right columns. Right JOIN → NULLs in left columns."
        }
        if q.contains("null") {
            return "A NULL in a JOIN result is a flag that says 'no matching record existed on this side.' It's not an error — it's data. A LEFT JOIN on Students-Clubs with Carol having no club will show `Carol | NULL` — telling you exactly who isn't assigned yet."
        }
        if q.contains("scenario") || q.contains("generate") {
            return "Scenario: An e-commerce company has an `Orders` table and a `Products` table. They want a report showing every order, including the product details if the product record still exists — but also preserving orders whose product was deleted from the catalogue. Which JOIN would you use, and why?"
        }
        if q.contains("fail") || q.contains("wrong") || q.contains("mistake") {
            if let quest = context.lastFailedQuest {
                return "In '\(quest.title)', the key clue was: \"\(quest.hint)\". The most common mistake is confusing which table should be the 'anchor.' Ask yourself: which table's rows must ALWAYS appear in the result, even without a match? That table determines your JOIN direction."
            }
            return "The most common JOIN mistake is confusing the ANCHOR table. Ask: which table's rows absolutely must appear, even if the other table has no match? That table belongs on the LEFT of a LEFT JOIN."
        }
        if q.contains("3") || q.contains("three") || q.contains("chain") || q.contains("pipeline") {
            return "3-table JOINs chain left-to-right: `A JOIN B ON ... JOIN C ON ...`. Think of it as a pipeline — the result of A+B becomes the new 'left table' for joining with C. Each junction can have its own JOIN type independently. Try the Advanced tab in SQLQuest to see this visually!"
        }
        if q.contains("difference") || q.contains("when to use") {
            return "Quick rule of thumb: INNER = 'I only want fully matched pairs.' LEFT = 'I need every row from my main table, optionally enriched by the second.' RIGHT = 'I need every row from my secondary table, optionally enriched by the first.' When in doubt, LEFT JOIN is the most commonly needed in real-world reporting."
        }

        return "Great question! SQL JOINs are fundamentally about combining rows from two tables based on a shared key. The JOIN type you choose determines what happens when a row has no match on the other side. Would you like me to walk through a specific scenario, or explain a particular JOIN type in depth?"
    }
}
