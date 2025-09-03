import SwiftUI

// MARK: - Colors

extension Color {
    static let appPrimary = Color.black
    static let appPrimaryDark = Color.black
    static let appPrimaryLight = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    static let appSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let appSecondaryDark = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let appSecondaryLight = Color(red: 0.6, green: 0.6, blue: 0.6)
    
    static let appBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let appSurface = Color.white
    
    static let appTextPrimary = Color.black
    static let appTextSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    static let appDivider = Color(red: 0.88, green: 0.88, blue: 0.88)
    
    // Status colors matching web interface
    static let statusGoing = Color(red: 0.2, green: 0.8, blue: 0.4) // Green for "Going"
    static let statusWaitlisted = Color(red: 1.0, green: 0.6, blue: 0.0) // Orange for "Waitlisted"
    static let statusNotGoing = Color(red: 0.9, green: 0.2, blue: 0.2) // Red for "Not Going"
    static let statusAdmin = Color(red: 0.2, green: 0.6, blue: 1.0) // Blue for "Group Admin"
    
    // Grey palette matching Material-UI
    static let grey50 = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let grey100 = Color(red: 0.96, green: 0.96, blue: 0.96)
    static let grey200 = Color(red: 0.93, green: 0.93, blue: 0.93)
    static let grey300 = Color(red: 0.88, green: 0.88, blue: 0.88)
    static let grey400 = Color(red: 0.74, green: 0.74, blue: 0.74)
    static let grey500 = Color(red: 0.62, green: 0.62, blue: 0.62)
    static let grey600 = Color(red: 0.46, green: 0.46, blue: 0.46)
    static let grey700 = Color(red: 0.38, green: 0.38, blue: 0.38)
    static let grey800 = Color(red: 0.26, green: 0.26, blue: 0.26)
    static let grey900 = Color(red: 0.13, green: 0.13, blue: 0.13)
}

// MARK: - Typography

struct AppTypography {
    static let h1 = Font.system(size: 40, weight: .bold, design: .default)
    static let h2 = Font.system(size: 32, weight: .semibold, design: .default)
    static let h3 = Font.system(size: 24, weight: .semibold, design: .default)
    static let h4 = Font.system(size: 20, weight: .semibold, design: .default)
    static let h5 = Font.system(size: 18, weight: .medium, design: .default)
    static let h6 = Font.system(size: 16, weight: .medium, design: .default)
    
    static let body1 = Font.system(size: 16, weight: .regular, design: .default)
    static let body2 = Font.system(size: 14, weight: .regular, design: .default)
    
    static let button = Font.system(size: 14, weight: .medium, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
}

// MARK: - Spacing

struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

struct AppCornerRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let xl: CGFloat = 16
}

// MARK: - Shadows

struct AppShadows {
    static let small = Shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    static let medium = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 4)
    static let large = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 8)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func appShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.appPrimary)
            .cornerRadius(AppCornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundColor(Color.appPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(Color.appDivider, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundColor(Color.appPrimary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Style

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .cornerRadius(AppCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .stroke(Color.appDivider, lineWidth: 1)
            )
            .appShadow(AppShadows.small)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}

// MARK: - Text Field Style

struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(Color.appDivider, lineWidth: 1)
            )
    }
}

// MARK: - Status Tag

struct StatusTag: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(color)
            .cornerRadius(AppCornerRadius.large)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    init(_ message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color.appSecondary)
            
            Text("Error")
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            Text(message)
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
            
            if let retryAction = retryAction {
                Button("Retry") {
                    retryAction()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
