import SwiftUI

// MARK: - GameProgressViewModel

@MainActor
final class GameProgressViewModel: ObservableObject {

    @AppStorage("sqlquest_totalXP")      var totalXP: Int = 0
    @AppStorage("sqlquest_streak")       var currentStreak: Int = 0
    @AppStorage("sqlquest_completedIDs") private var completedIDsRaw: String = ""

    // MARK: Level — SF Symbol names instead of emoji

    struct LevelInfo {
        let title  : String
        let icon   : String   // SF Symbol name
        let color  : Color
    }

    var levelInfo: LevelInfo {
        switch totalXP {
        case 0..<100:
            return LevelInfo(title: "SQL Newbie",        icon: "leaf.fill",          color: .green)
        case 100..<300:
            return LevelInfo(title: "JOIN Explorer",     icon: "magnifyingglass",    color: .blue)
        case 300..<600:
            return LevelInfo(title: "Query Craftsman",   icon: "wrench.and.screwdriver.fill", color: .purple)
        case 600..<1000:
            return LevelInfo(title: "Schema Architect",  icon: "building.columns.fill", color: .orange)
        default:
            return LevelInfo(title: "Database Sensei",   icon: "crown.fill",         color: Color(red: 1.0, green: 0.80, blue: 0.0))
        }
    }

    var level      : String { levelInfo.title }
    var levelColor : Color  { levelInfo.color }

    var levelProgress: Double {
        let thresholds = [0, 100, 300, 600, 1000, 1500]
        for i in 0..<thresholds.count - 1 {
            if totalXP < thresholds[i + 1] {
                let lo = Double(thresholds[i]);  let hi = Double(thresholds[i + 1])
                return min((Double(totalXP) - lo) / (hi - lo), 1.0)
            }
        }
        return 1.0
    }

    // MARK: Quest Tracking

    var completedIDs: Set<String> {
        get { Set(completedIDsRaw.split(separator: ",").map(String.init)) }
        set { completedIDsRaw = newValue.joined(separator: ",") }
    }

    func isCompleted(_ quest: Quest) -> Bool { completedIDs.contains(quest.id.uuidString) }

    func markCompleted(_ quest: Quest) {
        var ids = completedIDs; ids.insert(quest.id.uuidString); completedIDs = ids
    }

    // MARK: XP

    func awardXP(hintsUsed: Int, answeredFast: Bool) -> Int {
        var xp = 100
        xp -= hintsUsed * 20
        if answeredFast { xp += 30 }
        xp = max(xp, 10)
        totalXP += xp;  currentStreak += 1
        return xp
    }

    func penalizeWrongAnswer() { currentStreak = 0 }

    func resetProgress() { totalXP = 0; currentStreak = 0; completedIDs = [] }
}
