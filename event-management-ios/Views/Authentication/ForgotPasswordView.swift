import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 64))
                            .foregroundColor(.appPrimary)
                        
                        VStack(spacing: 8) {
                            Text("Forgot Password?")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Enter your email address and we'll send you a link to reset your password.")
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
            .navigationTitle("Forgot Password")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Forgot Password")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Reset Link Sent", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("If an account with that email exists, we've sent a password reset link.")
            }
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
