import SwiftUI

struct AppTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var validation: ((String) -> String?)? = nil
    
    @State private var errorMessage: String?
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextPrimary)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(AppTextFieldStyle())
                    .onChange(of: text) { newValue in
                        validateText(newValue)
                    }
                    .onTapGesture {
                        isEditing = true
                    }
                    .onSubmit {
                        isEditing = false
                    }
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(AppTextFieldStyle())
                    .onChange(of: text) { newValue in
                        validateText(newValue)
                    }
                    .onTapGesture {
                        isEditing = true
                    }
                    .onSubmit {
                        isEditing = false
                    }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
    
    private func validateText(_ text: String) {
        if let validation = validation {
            errorMessage = validation(text)
        } else {
            errorMessage = nil
        }
    }
}

struct AppTextArea: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var maxLength: Int? = nil
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextPrimary)
            
            TextEditor(text: $text)
                .frame(minHeight: 100)
                .padding(AppSpacing.md)
                .background(Color.appSurface)
                .cornerRadius(AppCornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .stroke(Color.appDivider, lineWidth: 1)
                )
                .onChange(of: text) { newValue in
                    if let maxLength = maxLength, newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }
            
            if let maxLength = maxLength {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(AppTypography.caption)
                        .foregroundColor(Color.appTextSecondary)
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        AppTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant("")
        )
        
        AppTextField(
            title: "Password",
            placeholder: "Enter your password",
            text: .constant(""),
            isSecure: true
        )
        
        AppTextArea(
            title: "Description",
            placeholder: "Enter description",
            text: .constant(""),
            maxLength: 1000
        )
    }
    .padding()
    .background(Color.appBackground)
}
