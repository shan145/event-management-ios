import SwiftUI

struct AppButton: View {
    let title: String
    let action: () -> Void
    var style: AppButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    
    enum AppButtonStyle {
        case primary
        case secondary
        case text
        case destructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: buttonTextColor))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(title)
                        .font(AppTypography.button)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(buttonStyle)
        .disabled(isLoading || isDisabled)
        .opacity(isLoading || isDisabled ? 0.6 : 1.0)
    }
    
    private var buttonStyle: AnyButtonStyle {
        switch style {
        case .primary:
            AnyButtonStyle(PrimaryButtonStyle())
        case .secondary:
            AnyButtonStyle(SecondaryButtonStyle())
        case .text:
            AnyButtonStyle(TextButtonStyle())
        case .destructive:
            AnyButtonStyle(DestructiveButtonStyle())
        }
    }
    
    private var buttonTextColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .text, .destructive:
            return Color.appPrimary
        }
    }
}

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView
    
    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.red)
            .cornerRadius(AppCornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.red)
            .cornerRadius(AppCornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = Color.appPrimary
    var size: CGFloat = 24
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(Color.clear)
                .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = Color.appPrimary
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
                .appShadow(AppShadows.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        AppButton(title: "Primary Button", action: {
            print("Primary tapped")
        })
        
        AppButton(title: "Secondary Button", action: {
            print("Secondary tapped")
        }, style: .secondary)
        
        AppButton(title: "Text Button", action: {
            print("Text tapped")
        }, style: .text)
        
        AppButton(title: "Loading Button", action: {
            print("Loading tapped")
        }, isLoading: true)
        
        AppButton(title: "Disabled Button", action: {
            print("Disabled tapped")
        }, isDisabled: true)
        
        AppButton(title: "Icon Button", action: {
            print("Icon tapped")
        }, icon: "plus")
        
        AppButton(title: "Destructive Button", action: {
            print("Destructive tapped")
        }, style: .destructive)
        
        HStack {
            IconButton(icon: "heart", action: { print("Heart tapped") })
            IconButton(icon: "star", action: { print("Star tapped") })
            IconButton(icon: "share", action: { print("Share tapped") })
        }
    }
    .padding()
    .background(Color.appBackground)
}
