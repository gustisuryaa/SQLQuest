import Foundation
import SwiftUI

// MARK: - Join Type

enum JoinType: String, CaseIterable {
    case inner = "INNER JOIN"
    case left  = "LEFT JOIN"
    case right = "RIGHT JOIN"

    var label: String { rawValue }

    var icon: String {
        switch self {
        case .inner: return "smallcircle.filled.circle.fill"
        case .left:  return "circle.lefthalf.filled"
        case .right: return "circle.righthalf.filled"
        }
    }

    var color: Color {
        switch self {
        case .inner: return .purple
        case .left:  return .blue
        case .right: return .orange
        }
    }

    var sqlDescription: String {
        switch self {
        case .inner: return "Returns only rows where both tables have a matching record."
        case .left:  return "Returns all rows from the LEFT table; NULLs fill missing right-side data."
        case .right: return "Returns all rows from the RIGHT table; NULLs fill missing left-side data."
        }
    }
}

// MARK: - Classic Two-Table Models (Exploration tab)

struct Student: Identifiable {
    let id: Int
    let name: String
}

struct Club: Identifiable {
    let id: Int
    let clubName: String
}

struct JoinedResult: Identifiable {
    let id         = UUID()
    let studentId  : String
    let studentName: String
    let clubName   : String
}

// MARK: - Generic Multi-Table Models (Advanced Exploration)

struct DBColumn {
    let name        : String
    let isPrimaryKey: Bool
    let isForeignKey: Bool
    init(_ name: String, pk: Bool = false, fk: Bool = false) {
        self.name         = name
        self.isPrimaryKey = pk
        self.isForeignKey = fk
    }
}

struct DBRow: Identifiable {
    let id    = UUID()
    let cells : [String: String]   // column name → value
}

struct DBTable: Identifiable {
    let id         = UUID()
    let name       : String
    let columns    : [DBColumn]
    let rows       : [DBRow]
    let accentColor: Color
}

// Dynamic result row for multi-table joins
struct DynamicRow: Identifiable {
    let id      = UUID()
    let columns : [String]          // ordered column names
    let values  : [String: String]  // value or "NULL"
}

// MARK: - Quest Progression

enum QuestDifficulty: String, CaseIterable, Identifiable {
    case newbie  = "Newbie"
    case easy    = "Easy"
    case medium  = "Medium"
    case hard    = "Hard"
    case expert  = "SQL Expert"

    var id: Self { self }

    var color: Color {
        switch self {
        case .newbie: return .green
        case .easy:   return .teal
        case .medium: return .blue
        case .hard:   return .orange
        case .expert: return .purple
        }
    }

    var icon: String {
        switch self {
        case .newbie: return "leaf.fill"
        case .easy:   return "star.fill"
        case .medium: return "flame.fill"
        case .hard:   return "bolt.fill"
        case .expert: return "crown.fill"
        }
    }

    var timeLimit: Double {
        switch self {
        case .newbie: return 60
        case .easy:   return 45
        case .medium: return 40
        case .hard:   return 35
        case .expert: return 30
        }
    }
}

enum QuestMechanic: String {
    case multipleChoice   = "Multiple Choice"
    case sqlBuilder       = "SQL Builder"      // tap token → fills blank in SQL
    case reverseEngineer  = "Reverse Engineer" // given result table, identify JOIN
    case sequenceOrder    = "Sequence Order"   // arrange SQL clauses in correct order
}

// MARK: - App Navigation

enum AppSection: String, CaseIterable, Identifiable {
    case exploration    = "Explore Joins"
    case advanced       = "3-Table Joins"
    case quest          = "Quest Mode"
    case ai             = "AI Tutor"

    var id: Self { self }

    var icon: String {
        switch self {
        case .exploration: return "circle.lefthalf.filled.righthalf.striped.horizontal"
        case .advanced:    return "circles.hexagongrid.fill"
        case .quest:       return "gamecontroller.fill"
        case .ai:          return "sparkles"
        }
    }

    var subtitle: String {
        switch self {
        case .exploration: return "Visualize SQL Joins interactively"
        case .advanced:    return "Explore 3-way joins & pipelines"
        case .quest:       return "Challenge your knowledge"
        case .ai:          return "Learn with your personal SQL tutor"
        }
    }

    var color: Color {
        switch self {
        case .exploration: return .blue
        case .advanced:    return .teal
        case .quest:       return .orange
        case .ai:          return .purple
        }
    }
}
