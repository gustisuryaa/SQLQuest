import SwiftUI

// MARK: - MultiTableViewModel
// Powers the Advanced (3-Table) Exploration tab.
// Models a classic Students → Enrollments → Courses schema.
// The user independently selects a JOIN type for each junction (A↔B and B↔C).

@MainActor
final class MultiTableViewModel: ObservableObject {

    // Each junction has its own independently selectable JOIN type
    @Published var joinAB: JoinType = .inner   // Students ↔ Enrollments
    @Published var joinBC: JoinType = .inner   // Enrollments ↔ Courses

    // MARK: - Tables

    let students: DBTable = DBTable(
        name: "Students",
        columns: [DBColumn("id", pk: true), DBColumn("name")],
        rows: [
            DBRow(cells: ["id": "1", "name": "Alice"]),
            DBRow(cells: ["id": "2", "name": "Bob"]),
            DBRow(cells: ["id": "3", "name": "Carol"])
        ],
        accentColor: .blue
    )

    let enrollments: DBTable = DBTable(
        name: "Enrollments",
        columns: [DBColumn("student_id", fk: true), DBColumn("course_id", fk: true)],
        rows: [
            DBRow(cells: ["student_id": "1", "course_id": "101"]),
            DBRow(cells: ["student_id": "1", "course_id": "102"]),
            DBRow(cells: ["student_id": "2", "course_id": "101"])
            // Carol (3) has no enrollments — great for LEFT JOIN demo
        ],
        accentColor: .teal
    )

    let courses: DBTable = DBTable(
        name: "Courses",
        columns: [DBColumn("id", pk: true), DBColumn("title")],
        rows: [
            DBRow(cells: ["id": "101", "title": "Swift Fundamentals"]),
            DBRow(cells: ["id": "102", "title": "Database Design"]),
            DBRow(cells: ["id": "103", "title": "UI/UX Principles"])  // no enrollments
        ],
        accentColor: .orange
    )

    // MARK: - SQL Preview

    var generatedSQL: String {
        """
        SELECT s.name, e.course_id, c.title
        FROM Students s
        \(joinAB.rawValue) Enrollments e
          ON s.id = e.student_id
        \(joinBC.rawValue) Courses c
          ON e.course_id = c.id;
        """
    }

    // MARK: - Join Result Computation
    // Phase 1: Join Students ↔ Enrollments
    // Phase 2: Join result ↔ Courses

    var joinResults: [DynamicRow] {
        let columns = ["student_id", "student_name", "course_id", "course_title"]

        // --- Phase 1: Students ↔ Enrollments ---
        var phase1: [(studentId: String, studentName: String, courseId: String)] = []

        switch joinAB {
        case .inner:
            for sRow in students.rows {
                let sid = sRow.cells["id"] ?? ""
                let matchedE = enrollments.rows.filter { $0.cells["student_id"] == sid }
                for e in matchedE {
                    phase1.append((sid, sRow.cells["name"] ?? "", e.cells["course_id"] ?? ""))
                }
            }
        case .left:
            for sRow in students.rows {
                let sid = sRow.cells["id"] ?? ""
                let matchedE = enrollments.rows.filter { $0.cells["student_id"] == sid }
                if matchedE.isEmpty {
                    phase1.append((sid, sRow.cells["name"] ?? "", "NULL"))
                } else {
                    for e in matchedE {
                        phase1.append((sid, sRow.cells["name"] ?? "", e.cells["course_id"] ?? ""))
                    }
                }
            }
        case .right:
            for eRow in enrollments.rows {
                let cid    = eRow.cells["course_id"] ?? ""
                let sid    = eRow.cells["student_id"] ?? ""
                let sMatch = students.rows.first(where: { $0.cells["id"] == sid })
                phase1.append((sMatch?.cells["id"] ?? "NULL", sMatch?.cells["name"] ?? "NULL", cid))
            }
            // Also include enrollments whose student has no match (shouldn't happen with FK but safe)
        }

        // --- Phase 2: Phase1 result ↔ Courses ---
        var final: [DynamicRow] = []

        switch joinBC {
        case .inner:
            for row in phase1 where row.courseId != "NULL" {
                if let course = courses.rows.first(where: { $0.cells["id"] == row.courseId }) {
                    final.append(DynamicRow(columns: columns, values: [
                        "student_id":    row.studentId,
                        "student_name":  row.studentName,
                        "course_id":     row.courseId,
                        "course_title":  course.cells["title"] ?? "NULL"
                    ]))
                }
            }
        case .left:
            for row in phase1 {
                let course = row.courseId == "NULL" ? nil : courses.rows.first(where: { $0.cells["id"] == row.courseId })
                final.append(DynamicRow(columns: columns, values: [
                    "student_id":    row.studentId,
                    "student_name":  row.studentName,
                    "course_id":     row.courseId,
                    "course_title":  course?.cells["title"] ?? "NULL"
                ]))
            }
        case .right:
            for course in courses.rows {
                let cid = course.cells["id"] ?? ""
                let matchedRows = phase1.filter { $0.courseId == cid }
                if matchedRows.isEmpty {
                    final.append(DynamicRow(columns: columns, values: [
                        "student_id":    "NULL",
                        "student_name":  "NULL",
                        "course_id":     cid,
                        "course_title":  course.cells["title"] ?? ""
                    ]))
                } else {
                    for row in matchedRows {
                        final.append(DynamicRow(columns: columns, values: [
                            "student_id":    row.studentId,
                            "student_name":  row.studentName,
                            "course_id":     cid,
                            "course_title":  course.cells["title"] ?? ""
                        ]))
                    }
                }
            }
        }

        return final
    }

    // MARK: - Insight text

    var insightText: String {
        let count = joinResults.count
        let nullCount = joinResults.filter { $0.values.values.contains("NULL") }.count

        switch (joinAB, joinBC) {
        case (.inner, .inner):
            return "\(count) rows — only fully matched records across all 3 tables."
        case (.left, .left):
            return "\(count) rows (\(nullCount) with NULLs) — all students preserved, missing data filled as NULL."
        case (.left, .inner):
            return "\(count) rows — all students shown, but only those enrolled in an existing course."
        default:
            return "\(count) rows returned with current JOIN configuration."
        }
    }
}
