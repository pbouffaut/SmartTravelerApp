import SwiftUI

// MARK: - Design System
// Premium dark theme inspired by HomeClaude & ShutterPhil aesthetic

struct ST {
    // MARK: Colors
    struct Colors {
        static let background = Color(hex: "#0A0A0A")
        static let surface = Color(hex: "#141414")
        static let card = Color(hex: "#1C1C1E")
        static let accent = Color(hex: "#B8965A")
        static let accentTint = Color(hex: "#B8965A").opacity(0.14)

        static let textPrimary = Color(hex: "#F5F5F7")
        static let textSecondary = Color(hex: "#8E8E93")
        static let textTertiary = Color(hex: "#48484A")

        static let border = Color.white.opacity(0.07)
        static let borderMid = Color.white.opacity(0.12)

        static let success = Color(hex: "#30D158")
        static let danger = Color(hex: "#FF453A")
        static let dangerTint = Color(hex: "#FF453A").opacity(0.12)
    }

    // MARK: Radii
    struct Radius {
        static let card: CGFloat = 16
        static let input: CGFloat = 14
        static let button: CGFloat = 14
        static let pill: CGFloat = 100
    }

    // MARK: Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Typography
    struct Font {
        static func title(_ size: CGFloat = 20) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .default)
        }
        static func heading(_ size: CGFloat = 17) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .default)
        }
        static func body(_ size: CGFloat = 15) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .default)
        }
        static func caption(_ size: CGFloat = 13) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .default)
        }
        static func label(_ size: CGFloat = 11) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .default)
        }
        static func mono(_ size: CGFloat = 28) -> SwiftUI.Font {
            .system(size: size, weight: .light, design: .monospaced)
        }
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Reusable Components

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(ST.Spacing.m)
            .background(ST.Colors.card)
            .cornerRadius(ST.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: ST.Radius.card)
                    .stroke(ST.Colors.border, lineWidth: 0.5)
            )
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: ST.Spacing.s) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ST.Colors.accent)
            }
            Text(title.uppercased())
                .font(ST.Font.label())
                .tracking(1.5)
                .foregroundColor(ST.Colors.textSecondary)
        }
    }
}

struct AccentButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: ST.Spacing.s) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(ST.Font.caption())
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, ST.Spacing.m)
            .padding(.vertical, 10)
            .background(ST.Colors.accent)
            .cornerRadius(ST.Radius.button)
        }
    }
}

struct GhostButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: ST.Spacing.s) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(ST.Font.caption())
                    .fontWeight(.medium)
            }
            .foregroundColor(ST.Colors.accent)
            .padding(.horizontal, ST.Spacing.m)
            .padding(.vertical, 10)
            .background(ST.Colors.accentTint)
            .cornerRadius(ST.Radius.button)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(ST.Colors.accent)
                    .frame(width: 28, height: 28)
                    .background(ST.Colors.accentTint)
                    .cornerRadius(7)

                Text(title)
                    .font(ST.Font.body())
                    .foregroundColor(ST.Colors.textPrimary)

                Spacer()

                Text(value)
                    .font(ST.Font.body())
                    .foregroundColor(ST.Colors.textSecondary)

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ST.Colors.textTertiary)
                }
            }
            .padding(.vertical, 6)
        }
        .disabled(action == nil)
    }
}

// MARK: - View Modifiers

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ST.Colors.background.ignoresSafeArea())
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}
