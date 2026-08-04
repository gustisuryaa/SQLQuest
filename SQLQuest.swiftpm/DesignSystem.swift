import SwiftUI

// MARK: - DesignSystem
// Single source of truth for all typography, spacing, and colour decisions.
// Every view in SQLQuest reads from here — changing one value fixes the whole app.

enum DS {

    // MARK: Typography
    // Uses Dynamic Type via TextStyle so the system respects user accessibility settings.
    // Sizes listed are the *default* point size at the Normal accessibility setting.

    enum Font {
        // Headings
        static let screenTitle  = SwiftUI.Font.system(.largeTitle,  design: .rounded).weight(.heavy)
        static let sectionTitle = SwiftUI.Font.system(.title2,      design: .rounded).weight(.bold)
        static let cardTitle    = SwiftUI.Font.system(.title3,      design: .rounded).weight(.semibold)
        static let groupHeader  = SwiftUI.Font.system(.headline,    design: .rounded).weight(.bold)

        // Body
        static let body         = SwiftUI.Font.system(.body,        design: .default)
        static let bodyBold     = SwiftUI.Font.system(.body,        design: .default).weight(.semibold)
        static let subhead      = SwiftUI.Font.system(.subheadline, design: .default)
        static let subheadBold  = SwiftUI.Font.system(.subheadline, design: .default).weight(.semibold)

        // Code / monospaced — larger than before for legibility on Mac Catalyst
        static let code         = SwiftUI.Font.system(.body,        design: .monospaced)
        static let codeSm       = SwiftUI.Font.system(.subheadline, design: .monospaced)
        static let codeXs       = SwiftUI.Font.system(.callout,     design: .monospaced).weight(.semibold)

        // Labels & captions
        static let label        = SwiftUI.Font.system(.callout,     design: .rounded).weight(.semibold)
        static let caption      = SwiftUI.Font.system(.footnote,    design: .default)
        static let captionBold  = SwiftUI.Font.system(.footnote,    design: .default).weight(.semibold)
        static let micro        = SwiftUI.Font.system(.caption,     design: .default)
        static let microBold    = SwiftUI.Font.system(.caption,     design: .default).weight(.bold)
    }

    // MARK: Spacing
    enum Space {
        static let xs  : CGFloat = 4
        static let sm  : CGFloat = 8
        static let md  : CGFloat = 16
        static let lg  : CGFloat = 24
        static let xl  : CGFloat = 32
        static let xxl : CGFloat = 48
    }

    // MARK: Radius
    enum Radius {
        static let sm  : CGFloat = 10
        static let md  : CGFloat = 14
        static let lg  : CGFloat = 18
        static let xl  : CGFloat = 24
        static let pill: CGFloat = 999
    }

    // MARK: Terminal / SQL colours (dark bg code blocks)
    enum SQL {
        static let background = Color(red: 0.07, green: 0.07, blue: 0.10)
        static let keyword    = Color(red: 0.35, green: 0.78, blue: 1.00)  // cyan
        static let tableName  = Color(red: 1.00, green: 0.85, blue: 0.40)  // amber
        static let punctuation = Color(red: 0.60, green: 0.90, blue: 0.65) // mint
        static let selector   = Color(red: 0.95, green: 0.55, blue: 0.30)  // orange-red (*)
        static let joinInner  = Color(red: 0.75, green: 0.45, blue: 1.00)  // violet
        static let joinLeft   = Color(red: 0.40, green: 0.75, blue: 1.00)  // sky
        static let joinRight  = Color(red: 1.00, green: 0.65, blue: 0.30)  // peach
    }
}

// MARK: - Adaptive Venn Size
// Computes circle diameter as a proportion of the available container width,
// so Venn diagrams scale from iPhone mini to Mac Catalyst fullscreen.

struct VennMetrics {
    let diameter  : CGFloat  // each circle's diameter
    let overlap   : CGFloat  // negative HStack spacing (overlap amount)
    let padding   : CGFloat  // surrounding padding for glow room
    let labelSize : CGFloat  // font point size for circle label

    static func from(containerWidth w: CGFloat) -> VennMetrics {
        let d = min(w * 0.32, 280)   // cap at 280pt on very wide screens
        return VennMetrics(
            diameter:  d,
            overlap:   d * 0.40,     // circles overlap by 40 % of their diameter
            padding:   d * 0.22,
            labelSize: max(d * 0.10, 13)
        )
    }
}
