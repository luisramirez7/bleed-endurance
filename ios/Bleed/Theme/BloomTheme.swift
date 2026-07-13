import SwiftUI
import BleedCore

/// Bloom, Bleed's visual language. Tokens mirror the design system's
/// tokens/colors.css. Warm plum-brown neutrals on blush cream, never
/// cold grey; shadows are soft and purple-tinted.
enum Bloom {
    // Brand palette
    static let flareOrange = Color(hex: 0xF0592B)
    static let bloomPurple = Color(hex: 0x8B5CF6)
    static let skyBlue = Color(hex: 0x3FA9F0)
    static let coralPink = Color(hex: 0xF26E8C)
    static let amber = Color(hex: 0xF2A83C)

    // Purple ramp
    static let purple700 = Color(hex: 0x5F3A8A)
    static let purple600 = Color(hex: 0x7A4BB0)

    // Neutrals (warm, plum-brown cast)
    static let ink = Color(hex: 0x3A2A33)
    static let inkSoft = Color(hex: 0x6B5661)
    static let inkMute = Color(hex: 0xB98A97)

    // Surfaces
    static let bgCream = Color(hex: 0xFBEFEC)
    static let surface = Color.white
    static let surfaceLilac = Color(hex: 0xF3ECFB)

    /// The house shadow: soft, purple-tinted, never neutral grey.
    static let cardShadow = Color(hex: 0x8B5CF6).opacity(0.10)

    /// The house glyph, used sparingly for delight. No other emoji.
    static let sparkle = "✦"
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Type

extension Font {
    /// Baloo 2: every heading, score, and numeral.
    static func baloo(_ size: CGFloat, _ weight: BalooWeight = .extraBold) -> Font {
        .custom(weight.rawValue, size: size)
    }

    /// Nunito: body copy and labels.
    static func nunito(_ size: CGFloat, _ weight: NunitoWeight = .semiBold) -> Font {
        .custom(weight.rawValue, size: size)
    }

    enum BalooWeight: String {
        case medium = "Baloo2-Medium"
        case semiBold = "Baloo2-SemiBold"
        case bold = "Baloo2-Bold"
        case extraBold = "Baloo2-ExtraBold"
    }

    enum NunitoWeight: String {
        case regular = "Nunito-Regular"
        case semiBold = "Nunito-SemiBold"
        case bold = "Nunito-Bold"
        case extraBold = "Nunito-ExtraBold"
    }
}

// MARK: - Phase styling

/// The app surface never uses clinical phase names; the nicknames and
/// their colours are the product's vocabulary (see the Bloom readme).
extension CyclePhase {
    var nickname: String {
        switch self {
        case .menstrual: "Bleed"
        case .follicular: "Rise"
        case .ovulatory: "Peak"
        case .luteal: "Wind-down"
        }
    }

    var color: Color {
        switch self {
        case .menstrual: Bloom.flareOrange
        case .follicular: Bloom.amber
        case .ovulatory: Bloom.skyBlue
        case .luteal: Bloom.bloomPurple
        }
    }

    var tint: Color {
        switch self {
        case .menstrual: Color(hex: 0xFDE9E1)
        case .follicular: Color(hex: 0xFCF0DD)
        case .ovulatory: Color(hex: 0xE2F1FC)
        case .luteal: Color(hex: 0xEEE8FB)
        }
    }

    /// Deep-toned companion for text set on the tint.
    var textColor: Color {
        switch self {
        case .menstrual: Color(hex: 0xB03A14)
        case .follicular: Color(hex: 0xB5760F)
        case .ovulatory: Color(hex: 0x1E6FA8)
        case .luteal: Bloom.purple600
        }
    }
}

// MARK: - Recommendation styling

extension TrainingRecommendation {
    /// The warm phrase for each state, straight from the design system.
    var phrase: String {
        switch self {
        case .proceed: "You're clear, go for it"
        case .holdPlan: "Hold the plan, monitor"
        case .reduceIntensity: "Ease off the intensity"
        case .rest: "Rest up today, gorgeous"
        }
    }

    var color: Color {
        switch self {
        case .proceed: Bloom.skyBlue
        case .holdPlan: Bloom.bloomPurple
        case .reduceIntensity: Bloom.amber
        case .rest: Bloom.coralPink
        }
    }

    var textColor: Color {
        switch self {
        case .proceed: Color(hex: 0x1E6FA8)
        case .holdPlan: Bloom.purple600
        case .reduceIntensity: Color(hex: 0xB5760F)
        case .rest: Color(hex: 0xC13E60)
        }
    }
}

// MARK: - Shared card chrome

struct BloomCard: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Bloom.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Bloom.cardShadow, radius: 9, y: 6)
    }
}

extension View {
    func bloomCard(padding: CGFloat = 18) -> some View {
        modifier(BloomCard(padding: padding))
    }
}

/// Pill chip like "Luteal · Day 22", tinted with the given colour.
struct BloomChip: View {
    let text: String
    let color: Color
    let textColor: Color
    var uppercased = true

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.nunito(uppercased ? 10 : 11, .extraBold))
                .textCase(uppercased ? .uppercase : nil)
                .kerning(uppercased ? 0.4 : 0)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(color.opacity(0.14), in: Capsule())
    }
}
