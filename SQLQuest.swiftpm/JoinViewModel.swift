import SwiftUI

// MARK: - JoinViewModel
// Drives the two-table Exploration tab.
// Handles join computation, NLP parsing, and accessibility descriptions.

@MainActor
final class JoinViewModel: ObservableObject {

    @Published var selectedJoin: JoinType = .inner

    // MARK: - Source Data

    let students: [Student] = [
        Student(id: 1, name: "Alice"),
        Student(id: 2, name: "Bob"),
        Student(id: 3, name: "Carol")
    ]

    let clubs: [Club] = [
        Club(id: 1, clubName: "iOS Club"),
        Club(id: 2, clubName: "Robotics"),
        Club(id: 4, clubName: "Chess Club")   // id=4 intentionally unmatched
    ]

    // MARK: - SQL String

    var generatedSQL: String {
        "SELECT *\nFROM Students\n\(selectedJoin.rawValue) Clubs\nON Students.id = Clubs.id;"
    }

    // MARK: - Join Computation

    var joinResults: [JoinedResult] {
        switch selectedJoin {
        case .inner:
            return students.compactMap { student in
                guard let club = clubs.first(where: { $0.id == student.id }) else { return nil }
                return JoinedResult(studentId: "\(student.id)", studentName: student.name, clubName: club.clubName)
            }

        case .left:
            return students.map { student in
                let club = clubs.first(where: { $0.id == student.id })
                return JoinedResult(studentId: "\(student.id)", studentName: student.name, clubName: club?.clubName ?? "NULL")
            }

        case .right:
            return clubs.map { club in
                let student = students.first(where: { $0.id == club.id })
                return JoinedResult(
                    studentId:   student.map { "\($0.id)" } ?? "NULL",
                    studentName: student?.name ?? "NULL",
                    clubName:    club.clubName
                )
            }
        }
    }

    // MARK: - NLP Processing
    // Keyword-based intent parser. Expands to AI-driven in AITutorViewModel.

    func processNaturalLanguage(query: String) {
        let q = query.lowercased()

        let leftSignals  = ["all students", "every student", "left", "include unmatched student", "student without"]
        let rightSignals = ["all clubs", "every club", "right", "include unmatched club", "club without"]
        let innerSignals = ["only matched", "intersection", "both tables", "matching", "only members"]

        if leftSignals.contains(where: q.contains) {
            withAnimation(.spring()) { selectedJoin = .left }
        } else if rightSignals.contains(where: q.contains) {
            withAnimation(.spring()) { selectedJoin = .right }
        } else if innerSignals.contains(where: q.contains) {
            withAnimation(.spring()) { selectedJoin = .inner }
        }
    }

    // MARK: - Accessibility

    var vennAccessibilityDescription: String {
        let count = joinResults.count
        switch selectedJoin {
        case .inner:
            return "Venn Diagram: INNER JOIN active. Only the overlapping intersection is highlighted — \(count) matching rows returned."
        case .left:
            return "Venn Diagram: LEFT JOIN active. The entire Students circle is highlighted — \(count) rows returned, including those with NULL club data."
        case .right:
            return "Venn Diagram: RIGHT JOIN active. The entire Clubs circle is highlighted — \(count) rows returned, including clubs with no student match."
        }
    }
}
