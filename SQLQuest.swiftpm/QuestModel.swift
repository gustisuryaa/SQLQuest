import Foundation
import SwiftUI

// MARK: - Quest Model

struct Quest: Identifiable {
    let id          = UUID()
    let title       : String
    let scenario    : String
    let hint        : String
    let correctJoin : JoinType
    let explanation : String
    let difficulty  : QuestDifficulty
    let mechanic    : QuestMechanic
    let resultSnapshot : [JoinedResult]?
    let sqlClauses     : [String]?

    init(title: String, scenario: String, hint: String,
         correctJoin: JoinType, explanation: String,
         difficulty: QuestDifficulty, mechanic: QuestMechanic,
         resultSnapshot: [JoinedResult]? = nil,
         sqlClauses: [String]? = nil) {
        self.title = title; self.scenario = scenario; self.hint = hint
        self.correctJoin = correctJoin; self.explanation = explanation
        self.difficulty = difficulty; self.mechanic = mechanic
        self.resultSnapshot = resultSnapshot; self.sqlClauses = sqlClauses
    }
}

// MARK: - Snapshot helpers (Reverse Engineer quests)

private func innerSnapshot() -> [JoinedResult] {[
    JoinedResult(studentId: "1", studentName: "Alice", clubName: "iOS Club"),
    JoinedResult(studentId: "2", studentName: "Bob",   clubName: "Robotics")
]}
private func leftSnapshot() -> [JoinedResult] {[
    JoinedResult(studentId: "1", studentName: "Alice", clubName: "iOS Club"),
    JoinedResult(studentId: "2", studentName: "Bob",   clubName: "Robotics"),
    JoinedResult(studentId: "3", studentName: "Carol", clubName: "NULL")
]}
private func rightSnapshot() -> [JoinedResult] {[
    JoinedResult(studentId: "1",    studentName: "Alice", clubName: "iOS Club"),
    JoinedResult(studentId: "2",    studentName: "Bob",   clubName: "Robotics"),
    JoinedResult(studentId: "NULL", studentName: "NULL",  clubName: "Chess Club")
]}

// MARK: - Quest Data (28 quests across 5 tiers)

let questData: [Quest] = [

    // ───────────────────────────── NEWBIE ─────────────────────────────────────

    Quest(
        title: "The Perfect Match",
        scenario: "The school yearbook team wants a photo spread of students WITH their club. They only want rows where both a student AND a club record exist — no empty slots allowed.",
        hint: "You need records that exist in BOTH tables simultaneously.",
        correctJoin: .inner,
        explanation: "INNER JOIN returns only rows with a matching key in both tables. Students without a club, and clubs with no student, are silently excluded — exactly what the yearbook team needs.",
        difficulty: .newbie, mechanic: .multipleChoice
    ),
    Quest(
        title: "The Full Attendance",
        scenario: "Student union wants a complete roll call of every enrolled student, along with their club. It's okay if some students haven't chosen a club yet — nobody should be left off the list.",
        hint: "All rows from the first (left) table must appear, even when the second table has no match.",
        correctJoin: .left,
        explanation: "LEFT JOIN preserves every row from the left table (Students). When no matching club exists the club column fills with NULL, giving the union a complete roster.",
        difficulty: .newbie, mechanic: .multipleChoice
    ),
    Quest(
        title: "First Day Report",
        scenario: "HR needs a quick list of every student who is already signed up for a club — just the confirmed members, no unassigned students cluttering the spreadsheet.",
        hint: "No NULLs wanted — every output row must be fully populated on both sides.",
        correctJoin: .inner,
        explanation: "INNER JOIN filters out any student without a club and any club without a student. Only strictly matched pairs survive, giving HR a clean confirmed-members list.",
        difficulty: .newbie, mechanic: .multipleChoice
    ),

    // ───────────────────────────── EASY ───────────────────────────────────────

    Quest(
        title: "The Ghost Clubs",
        scenario: "IT is auditing the Clubs table. They need a full list of every club in the system, with student info where available — even if a club hasn't recruited anyone yet.",
        hint: "Every row from the second (right) table must be preserved.",
        correctJoin: .right,
        explanation: "RIGHT JOIN ensures every club appears in the result. If no student has joined, the student columns show NULL, exposing 'ghost' clubs that exist only on paper.",
        difficulty: .easy, mechanic: .multipleChoice
    ),
    Quest(
        title: "The Campaign List",
        scenario: "Marketing is running a targeted campaign and needs ONLY students currently active in a club. Sending emails to unassigned students would waste resources — strict matching only.",
        hint: "Strict — no NULLs allowed. Both sides must have a record.",
        correctJoin: .inner,
        explanation: "INNER JOIN drops any row where either side lacks a match. Only strictly paired students and clubs survive, giving marketing a clean targeted list.",
        difficulty: .easy, mechanic: .multipleChoice
    ),
    Quest(
        title: "The Waitlist Report",
        scenario: "Admissions is reviewing club registrations. They want every student's name with their club assignment. Students on the waitlist (no club yet) must still appear, with the club field left blank.",
        hint: "The anchor is the Students table — every student must show up.",
        correctJoin: .left,
        explanation: "LEFT JOIN anchors on Students. Students without a matching club get NULL in the club column, which admissions can filter to identify waitlisted students.",
        difficulty: .easy, mechanic: .multipleChoice
    ),
    Quest(
        title: "The Missing Venues",
        scenario: "An event planner needs to see all sports clubs even if no students have registered yet, so they can allocate venues proactively. Student data can be NULL if no match exists.",
        hint: "Focus on the right-side table — every club must survive in the output.",
        correctJoin: .right,
        explanation: "RIGHT JOIN preserves all clubs from the right table regardless of student matches. Clubs with zero members show NULLs in student columns, signalling the planner they need proactive outreach.",
        difficulty: .easy, mechanic: .multipleChoice
    ),

    // ───────────────────────────── MEDIUM ─────────────────────────────────────

    Quest(
        title: "The Orphaned Records",
        scenario: "After a system migration, some student-to-club links were severed. An engineer needs every student record, flagging those whose club data is now missing (NULL). Complete the SQL below.",
        hint: "We need ALL students from the left table — the club column can be NULL.",
        correctJoin: .left,
        explanation: "LEFT JOIN is the correct choice. Every student appears in the output; NULL in the club column immediately identifies records orphaned by the migration.",
        difficulty: .medium, mechanic: .sqlBuilder
    ),
    Quest(
        title: "The Exclusive Registry",
        scenario: "Finance needs a billing report including every club on record — even those with zero members. Student data can be blank if no match exists. Fill in the missing JOIN keyword.",
        hint: "The non-negotiable requirement is that every CLUB row survives — the right-side table.",
        correctJoin: .right,
        explanation: "RIGHT JOIN guarantees all clubs appear regardless of member count. Clubs with no students show NULL in student columns — but they're still billed.",
        difficulty: .medium, mechanic: .sqlBuilder
    ),
    Quest(
        title: "The Intersection Report",
        scenario: "A compliance officer needs a report where EVERY column is populated — zero NULLs anywhere. Only students with an assigned club, and clubs with at least one member, should appear.",
        hint: "Zero tolerance for NULLs means only fully matched pairs survive.",
        correctJoin: .inner,
        explanation: "INNER JOIN is the only type that guarantees no NULL values in the result. Unmatched rows on either side are silently dropped, producing a fully populated report.",
        difficulty: .medium, mechanic: .sqlBuilder
    ),
    Quest(
        title: "The Absence Tracker",
        scenario: "A teacher needs to find which students have NOT been assigned to any club. She plans to filter the result for NULL club values. Build the correct query first.",
        hint: "You need ALL students first — then you'll filter where club = NULL. Which JOIN preserves every student row?",
        correctJoin: .left,
        explanation: "LEFT JOIN keeps every Student row. Students with no club get NULL in the club column. The teacher can then add WHERE clubName IS NULL to isolate unassigned students.",
        difficulty: .medium, mechanic: .sqlBuilder
    ),
    Quest(
        title: "The Dormant Assets",
        scenario: "A resource manager wants to know which clubs have not attracted any student members. She'll filter for NULLs — but first she needs the right query structure.",
        hint: "You need ALL clubs first — then filter where student = NULL. Which JOIN preserves every club row?",
        correctJoin: .right,
        explanation: "RIGHT JOIN preserves all clubs. Clubs with no members receive NULL in student columns. Adding WHERE studentName IS NULL reveals all dormant clubs with zero membership.",
        difficulty: .medium, mechanic: .sqlBuilder
    ),

    // ───────────────────────────── HARD ───────────────────────────────────────

    Quest(
        title: "The Silent Partners",
        scenario: "A colleague ran a query and left you the result table below. One row has NULL in the Club column. Which JOIN type produced this output — and why?",
        hint: "Look at which column contains NULL. NULLs on the right (Club) side tell you which table was treated as optional.",
        correctJoin: .left,
        explanation: "NULL in the Club column means the query kept all Students even when no club matched — the hallmark of LEFT JOIN. RIGHT JOIN would put NULLs in the Student columns instead.",
        difficulty: .hard, mechanic: .reverseEngineer, resultSnapshot: leftSnapshot()
    ),
    Quest(
        title: "The Unnamed Venue",
        scenario: "This result table was generated by a teammate. Notice that one row has NULL values in the Student columns. Determine which JOIN type was used.",
        hint: "NULLs in the student columns mean students were the 'optional' side — which JOIN makes the right table the anchor?",
        correctJoin: .right,
        explanation: "NULL in the student columns is the hallmark of RIGHT JOIN. The right table (Clubs) is fully preserved even when no student maps to that club.",
        difficulty: .hard, mechanic: .reverseEngineer, resultSnapshot: rightSnapshot()
    ),
    Quest(
        title: "The Clean Slate",
        scenario: "A query result was found in the logs. Every single row is fully populated — no NULLs anywhere. Identify which JOIN strategy was responsible for this perfectly clean output.",
        hint: "A perfectly NULL-free result means every row had a complete match on both sides.",
        correctJoin: .inner,
        explanation: "Only INNER JOIN produces a result with zero NULLs. Every row has a matching record in both tables. Unmatched rows were silently excluded.",
        difficulty: .hard, mechanic: .reverseEngineer, resultSnapshot: innerSnapshot()
    ),
    Quest(
        title: "The Forensic Query",
        scenario: "A bug report shows that a query is returning more rows than expected, and some student names appear multiple times with different club values. Inspect the result below — which JOIN produced it?",
        hint: "When every club still appears in the output even with no matching student, which side is the anchor?",
        correctJoin: .right,
        explanation: "RIGHT JOIN produces one row per club regardless of student matches. If multiple clubs share a student, that student appears multiple times — which explains the duplicates in the bug report.",
        difficulty: .hard, mechanic: .reverseEngineer, resultSnapshot: rightSnapshot()
    ),
    Quest(
        title: "The Partial Archive",
        scenario: "An archive export shows most rows have full data, but Carol's row has a NULL club. The archivist insists no records were deleted — all students were exported. Identify the JOIN used.",
        hint: "If all students were guaranteed to export (including Carol who has no club), which JOIN preserves all students?",
        correctJoin: .left,
        explanation: "LEFT JOIN guarantees every Student appears in the result. Carol has no club match, so her club column is NULL — not missing from the archive, just unassigned.",
        difficulty: .hard, mechanic: .reverseEngineer, resultSnapshot: leftSnapshot()
    ),

    // ────────────────────────── SQL EXPERT ────────────────────────────────────

    Quest(
        title: "The Fragmented Query",
        scenario: "A critical query was corrupted and its clauses scrambled. Reassemble the SQL statement in the correct logical order so the database can execute it without errors.",
        hint: "SQL always reads: what to SELECT → FROM where → how to JOIN → ON what condition.",
        correctJoin: .inner,
        explanation: "SQL clause order is fixed: SELECT defines columns, FROM specifies the base table, JOIN brings in the second table, ON defines the match condition. The engine processes them in this exact sequence.",
        difficulty: .expert, mechanic: .sequenceOrder,
        sqlClauses: ["ON Students.id = Clubs.id", "SELECT *", "INNER JOIN Clubs", "FROM Students"]
    ),
    Quest(
        title: "The Architect's Choice",
        scenario: "A client's brief states: 'I need every student in the output. If they have a club, great. If not, keep them anyway — mark the club as empty.' Build the query by selecting the right JOIN.",
        hint: "The client's emphasis on 'every student regardless of club' is a strong signal about which table is the anchor.",
        correctJoin: .left,
        explanation: "LEFT JOIN anchors on Students, preserving every student row. When no matching club exists, the club column receives NULL — perfectly matching 'keep them anyway'.",
        difficulty: .expert, mechanic: .sqlBuilder
    ),
    Quest(
        title: "The Audit Trail",
        scenario: "Compliance requires a full list of all clubs, complete with every student ever enrolled. Clubs with no members must still appear on the report. Reassemble the SQL correctly.",
        hint: "SQL reads top-to-bottom: what columns → which base table → which join → match condition.",
        correctJoin: .right,
        explanation: "RIGHT JOIN keeps all Clubs even with no student match. The SQL clause order (SELECT → FROM → JOIN → ON) is mandatory — swapping any clause causes a parse error.",
        difficulty: .expert, mechanic: .sequenceOrder,
        sqlClauses: ["ON Students.id = Clubs.id", "SELECT *", "RIGHT JOIN Clubs", "FROM Students"]
    ),
    Quest(
        title: "The NULL Detective",
        scenario: "A data scientist claims she can identify which JOIN was used just by counting NULLs. She shows you a result with 0 NULLs in the student columns and 1 NULL in the club column. What was her JOIN?",
        hint: "NULLs appear on the OPTIONAL side of a JOIN. Count which column has them.",
        correctJoin: .left,
        explanation: "NULL only in the club column means the club side was optional — LEFT JOIN. If RIGHT JOIN were used, NULLs would appear in student columns instead. Zero NULLs on both sides would indicate INNER JOIN.",
        difficulty: .expert, mechanic: .multipleChoice
    ),
    Quest(
        title: "The Schema Puzzle",
        scenario: "A senior engineer says: 'Use whichever join gives me a row for every club in our system, even if the club table has an entry for a club that no student has joined.' What is he asking for?",
        hint: "The engineer wants the right-side table (Clubs) fully preserved — including rows with no student match.",
        correctJoin: .right,
        explanation: "RIGHT JOIN is precisely what 'every club row, even unmatched ones' describes. The right table becomes the anchor; left-side student data fills in where available, and NULLs appear where it doesn't.",
        difficulty: .expert, mechanic: .multipleChoice
    ),
    Quest(
        title: "The Consistency Mandate",
        scenario: "A regulatory body mandates: 'The report must contain absolutely no NULL values. Any row with missing data must be excluded.' Which JOIN guarantees this outcome?",
        hint: "Only one JOIN type eliminates all NULLs by design — it only keeps fully matched pairs.",
        correctJoin: .inner,
        explanation: "INNER JOIN is the only JOIN type that structurally guarantees zero NULLs in the result. It excludes any row that lacks a complete match on both sides, satisfying the regulatory requirement exactly.",
        difficulty: .expert, mechanic: .multipleChoice
    ),
    Quest(
        title: "The Left-Side Anchor",
        scenario: "A database textbook defines: 'This join returns all rows from the first table in the FROM clause, plus matched rows from the second table. Unmatched rows from the second table are excluded; unmatched rows from the first table are retained with NULLs.' Which JOIN is being described?",
        hint: "The description says the FIRST table's rows are always kept — even without a match on the other side.",
        correctJoin: .left,
        explanation: "This is the textbook definition of LEFT JOIN. The 'left' table (written first after FROM) is the anchor — all its rows appear. The 'right' table contributes data where a match exists, and NULLs where it doesn't.",
        difficulty: .expert, mechanic: .multipleChoice
    ),
    Quest(
        title: "The Production Outage",
        scenario: "A developer's query was supposed to list ALL clubs for a dashboard. After deploying, clubs with no members vanished from the UI. He used INNER JOIN. Fix the bug by identifying the correct JOIN.",
        hint: "INNER JOIN excluded clubs with no student. Which JOIN would have preserved every club row?",
        correctJoin: .right,
        explanation: "The bug: INNER JOIN silently dropped clubs with no student matches. The fix is RIGHT JOIN, which preserves every club row regardless of whether any student is enrolled. Empty clubs appear with NULL student columns.",
        difficulty: .expert, mechanic: .multipleChoice
    ),

    // Extra Expert — Sequence Order
    Quest(
        title: "The LEFT JOIN Assembly",
        scenario: "You're onboarding a junior developer. Show them the correct SQL clause order for a LEFT JOIN query that includes all students even without a club.",
        hint: "SQL clause order is always: SELECT → FROM → JOIN type + table → ON condition.",
        correctJoin: .left,
        explanation: "The mandatory SQL order is SELECT (what) → FROM (base table) → JOIN TYPE + table (second table) → ON (match condition). Deviating from this order causes a syntax error in every major database engine.",
        difficulty: .expert, mechanic: .sequenceOrder,
        sqlClauses: ["ON Students.id = Clubs.id", "SELECT *", "LEFT JOIN Clubs", "FROM Students"]
    )
]

// MARK: - Grouping helper

extension Array where Element == Quest {
    func grouped() -> [(QuestDifficulty, [Quest])] {
        QuestDifficulty.allCases.compactMap { diff in
            let g = filter { $0.difficulty == diff }
            return g.isEmpty ? nil : (diff, g)
        }
    }
}
