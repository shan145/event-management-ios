import SwiftUI

struct SendEventEmailView: View {
    let event: Event
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
                
                Text("Send Email")
                    .font(AppTypography.h4)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("Send") {
                    sendEmail()
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
                    // Event info
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Event: \(event.title)")
                            .font(AppTypography.h5)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appTextPrimary)
                        
                        Text("To: Event attendees")
                            .font(AppTypography.body2)
                            .foregroundColor(Color.appTextSecondary)
                        
                        Text("Date: \(event.date)")
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
                        Text("Email sent successfully!")
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
    
    private func sendEmail() {
        guard !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Call the API endpoint: POST /events/:id/send-email
                let response = try await APIService.shared.sendEventEmail(
                    eventId: event.id,
                    subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                    message: message.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    print("✅ Email sent successfully: \(response.message ?? "Success")")
                    
                    // Auto-dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send email: \(error.localizedDescription)"
                    print("❌ Failed to send email: \(error)")
                }
            }
        }
    }
}

#Preview {
    SendEventEmailView(event: Event(
        id: "1",
        title: "Sample Event",
        description: "A sample event",
        location: EventLocation(name: "Sample Location", url: nil),
        date: "2025-01-15",
        time: "18:00",
        maxAttendees: nil,
        guests: 0,
        groupId: .id("group1"),
        createdBy: .id("user1"),
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z",
        goingList: [],
        waitlist: [],
        noGoList: []
    ))
}
