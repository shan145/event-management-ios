import SwiftUI

struct ResetPasswordView: View {
    let token: String
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ResetPasswordViewModel()
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 64))
                            .foregroundColor(.appPrimary)
                        
                        VStack(spacing: 8) {
                            Text("Reset Password")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Enter your new password below.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 24) {
                        AppTextField(
                            title: "New Password",
                            placeholder: "Enter your new password",
                            text: $viewModel.password,
                            isSecure: true
                        )
                        
                        AppTextField(
                            title: "Confirm Password",
                            placeholder: "Confirm your new password",
                            text: $viewModel.confirmPassword,
                            isSecure: true
                        )
                        
                        AppButton(
                            title: "Reset Password",
                            action: {
                                Task {
                                    await viewModel.resetPassword(token: token)
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
                    .padding(.horizontal)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Reset Password")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Reset Password")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Password Reset", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your password has been reset successfully. You can now log in with your new password.")
            }
        }
    }
}

// MARK: - ViewModel

class ResetPasswordViewModel: ObservableObject {
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    var isValid: Bool {
        !password.isEmpty && password.count >= 6 && password == confirmPassword
    }
    
    @MainActor
    func resetPassword(token: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.resetPassword(token: token, password: password)
            showSuccess = response.success
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Preview

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(token: "sample-token")
    }
}
