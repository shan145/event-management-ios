import SwiftUI

struct SendGroupMessageView: View {
    let group: Group
    @Environment(\.presentationMode) var presentationMode
    @State private var subject = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color.appPrimary)
                
                Spacer()
                
                Text("Send Message")
                    .font(AppTypography.h4)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("Send") {
                    sendMessage()
                }
                .foregroundColor(Color.appPrimary)
                .disabled(subject.isEmpty || message.isEmpty || isLoading)
            }
            .padding(AppSpacing.lg)
            .background(Color.appSurface)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Group info
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("To: \(group.name)")
                            .font(AppTypography.h5)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appTextPrimary)
                        
                        Text("\(group.memberCount) members")
                            .font(AppTypography.body2)
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Subject field
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Subject")
                            .font(AppTypography.body1)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appTextPrimary)
                        
                        TextField("Enter subject", text: $subject)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(AppTypography.body1)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Message field
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Message")
                            .font(AppTypography.body1)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appTextPrimary)
                        
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                            .padding(AppSpacing.sm)
                            .background(Color.grey100)
                            .cornerRadius(AppCornerRadius.medium)
                            .font(AppTypography.body1)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(AppTypography.body2)
                            .foregroundColor(Color.statusNotGoing)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    
                    if showSuccess {
                        Text("Message sent successfully!")
                            .font(AppTypography.body2)
                            .foregroundColor(Color.statusGoing)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    
                    Spacer(minLength: AppSpacing.lg)
                }
                .padding(.top, AppSpacing.lg)
            }
        }
        .background(Color.appBackground)
        .overlay {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    private func sendMessage() {
        guard !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // TODO: Implement group message sending via API
                // This would typically call something like:
                // let response = try await APIService.shared.sendGroupMessage(
                //     groupId: group.id,
                //     subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                //     message: message.trimmingCharacters(in: .whitespacesAndNewlines)
                // )
                
                // Simulate API call for now
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    
                    // Auto-dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send message: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    SendGroupMessageView(group: Group(
        id: "1",
        name: "Sample Group",
        adminId: nil,
        groupAdmins: [],
        members: [],
        tags: ["sports"],
        inviteToken: "token123",
        createdAt: "2025-01-01T00:00:00Z",
        eventCount: 3
    ))
}
