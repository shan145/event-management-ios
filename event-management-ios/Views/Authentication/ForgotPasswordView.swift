import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var showingSuccessAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.appPrimary)
                
                Spacer()
                
                Text("Forgot Password")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Invisible button for spacing
                Button("Cancel") {
                    // Empty action
                }
                .opacity(0)
                .disabled(true)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(Color.appSurface)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.appDivider),
                alignment: .bottom
            )
            
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 64))
                            .foregroundColor(.appPrimary)
                        
                        VStack(spacing: AppSpacing.sm) {
                            Text("Forgot Password?")
                                .font(AppTypography.h3)
                                .fontWeight(.bold)
                                .foregroundColor(.appTextPrimary)
                            
                            Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(AppTypography.body2)
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, AppSpacing.xl)
                    
                    // Form
                    VStack(spacing: AppSpacing.lg) {
                        AppTextField(
                            title: "Email Address",
                            placeholder: "Enter your email address",
                            text: $viewModel.email
                        )
                        
                        AppButton(
                            title: "Send Reset Link",
                            action: {
                                Task {
                                    await viewModel.sendResetLink()
                                    if viewModel.showSuccess {
                                        showingSuccessAlert = true
                                    }
                                }
                            },
                            style: .primary,
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.isValid
                        )
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(AppTypography.caption)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(Color.appBackground)
        .alert("Reset Link Sent", isPresented: $showingSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("If an account with that email exists, we've sent a password reset link.")
        }
    }
}

// MARK: - ViewModel

class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    var isValid: Bool {
        !email.isEmpty && email.contains("@")
    }
    
    @MainActor
    func sendResetLink() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.forgotPassword(email: email)
            showSuccess = response.success
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Preview

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
