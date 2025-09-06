import SwiftUI

struct EventEmailView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EventEmailViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Content
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Event Info Section
                    eventInfoSection
                    
                    // Email Content Section
                    emailContentSection
                    
                    // Spacer for bottom padding
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.xl)
            }
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .ignoresSafeArea(.container, edges: .bottom)
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(TextButtonStyle())
                
                Spacer()
                
                Text("Email Attendees")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("Send") {
                    Task {
                        await viewModel.sendEmail(to: event)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            
            Divider()
                .background(Color.appDivider)
        }
        .background(Color.appSurface)
    }
    
    private var eventInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Event Information")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color.appPrimary)
                        .frame(width: 20)
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(Color.grey600)
                        .frame(width: 20)
                    Text(event.formattedDateTime)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.appTextSecondary)
                }
                
                if let location = event.location, !location.name.isEmpty {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(Color.grey600)
                            .frame(width: 20)
                        Text(location.name)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.appTextSecondary)
                    }
                }
                
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(Color.statusGoing)
                        .frame(width: 20)
                    Text("\(getConfirmedAttendeesCount()) confirmed attendees will receive this email")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.appTextSecondary)
                }
            }
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var emailContentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Email Content")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextField(
                title: "Subject",
                placeholder: "Enter email subject",
                text: $viewModel.subject
            )
            
            AppTextArea(
                title: "Message",
                placeholder: "Enter your message to attendees...",
                text: $viewModel.message
            )
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Sending email...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private func getConfirmedAttendeesCount() -> Int {
        return event.goingList?.count ?? 0
    }
}

// MARK: - Event Email ViewModel

@MainActor
class EventEmailViewModel: ObservableObject {
    @Published var subject = ""
    @Published var message = ""
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var successMessage = ""
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    var isFormValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func sendEmail(to event: Event) async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let response = try await apiService.sendEventEmail(
                eventId: event.id,
                subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                message: message.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            successMessage = response.message ?? "Email sent successfully!"
            showSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

#Preview {
    EventEmailView(event: Event(
        id: "preview-id",
        title: "Preview Event",
        description: "This is a preview event",
        location: EventLocation(name: "Preview Location", url: nil),
        date: "2025-01-15",
        time: "19:00",
        maxAttendees: 20,
        guests: 2,
        groupId: .id("preview-group"),
        createdBy: .id("preview-user"),
        createdAt: "2025-01-01T00:00:00.000Z",
        updatedAt: "2025-01-01T00:00:00.000Z",
        goingList: [],
        waitlist: [],
        noGoList: []
    ))
}
