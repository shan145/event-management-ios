import SwiftUI

struct EventAttendeeManagementView: View {
    let event: Event
    let onEventUpdated: (() -> Void)?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = EventAttendeeManagementViewModel()
    @State private var selectedTab = 0
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @State private var isPerformingAction = false
    
    init(event: Event, onEventUpdated: (() -> Void)? = nil) {
        self.event = event
        self.onEventUpdated = onEventUpdated
    }
    
    private var canManageEvent: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        
        // Get the group ID from the event
        let groupId: String
        switch event.groupId {
        case .group(let group):
            groupId = group.id
        case .populatedGroup(let popGroup):
            groupId = popGroup.id
        case .id(let id):
            groupId = id
        }
        
        // Check if user is super admin or admin of this specific group
        return currentUser.isAdminOfGroup(groupId)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            VStack(spacing: 16) {
                HStack {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Attendee Management")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Empty space for balance
                    Color.clear
                        .frame(width: 50)
                }
                .padding(.horizontal)
                
                Image(systemName: "person.3")
                    .font(.system(size: 48))
                    .foregroundColor(.appPrimary)
                
                VStack(spacing: 8) {
                    Text("Manage Attendees")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(event.title)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.white.opacity(0.95))
            
            // Tab Picker
            HStack {
                Button("Going (\(viewModel.goingAttendees.count))") {
                    selectedTab = 0
                }
                .foregroundColor(selectedTab == 0 ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == 0 ? Color.blue : Color.clear)
                .cornerRadius(8)
                
                Button("Waitlist (\(viewModel.waitlistAttendees.count))") {
                    selectedTab = 1
                }
                .foregroundColor(selectedTab == 1 ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == 1 ? Color.blue : Color.clear)
                .cornerRadius(8)
                
                Button("Not Going (\(viewModel.notGoingAttendees.count))") {
                    selectedTab = 2
                }
                .foregroundColor(selectedTab == 2 ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == 2 ? Color.blue : Color.clear)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // Content
            if selectedTab == 0 {
                goingAttendeesList
            } else if selectedTab == 1 {
                waitlistAttendeesList
            } else if selectedTab == 2 {
                notGoingAttendeesList
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.loadEventAttendees(event: event)
        }
    }
    
    // MARK: - Supporting Views
    
    private var goingAttendeesList: some View {
        List {
            ForEach(viewModel.goingAttendees) { attendee in
                AttendeeRowView(
                    attendee: attendee,
                    status: "Going",
                    statusColor: .green,
                    actions: canManageEvent ? [
                        AttendeeAction(
                            title: "Move to Waitlist",
                            color: .orange,
                            action: {
                                Task {
                                    isPerformingAction = true
                                    let success = await viewModel.moveToWaitlist(eventId: event.id, userId: attendee.id)
                                    isPerformingAction = false
                                    if success {
                                        successMessage = "User moved to waitlist successfully"
                                        showingSuccessAlert = true
                                        onEventUpdated?()
                                    }
                                }
                            }
                        ),
                        AttendeeAction(
                            title: "Mark Not Going",
                            color: .red,
                            action: {
                                Task {
                                    isPerformingAction = true
                                    let success = await viewModel.rejectAttendee(eventId: event.id, userId: attendee.id)
                                    isPerformingAction = false
                                    if success {
                                        successMessage = "User marked as not going"
                                        showingSuccessAlert = true
                                        onEventUpdated?()
                                    }
                                }
                            }
                        )
                    ] : []
                )
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshEventData(eventId: event.id)
        }
    }
    
    private var waitlistAttendeesList: some View {
        List {
            ForEach(viewModel.waitlistAttendees) { attendee in
                AttendeeRowView(
                    attendee: attendee,
                    status: "Waitlist",
                    statusColor: .orange,
                    actions: canManageEvent ? [
                        AttendeeAction(
                            title: "Approve",
                            color: .green,
                            action: {
                                Task {
                                    isPerformingAction = true
                                    let success = await viewModel.approveAttendee(eventId: event.id, userId: attendee.id)
                                    isPerformingAction = false
                                    if success {
                                        successMessage = "User approved successfully"
                                        showingSuccessAlert = true
                                        onEventUpdated?()
                                    }
                                }
                            }
                        ),
                        AttendeeAction(
                            title: "Mark Not Going",
                            color: .red,
                            action: {
                                Task {
                                    isPerformingAction = true
                                    let success = await viewModel.rejectAttendee(eventId: event.id, userId: attendee.id)
                                    isPerformingAction = false
                                    if success {
                                        successMessage = "User marked as not going"
                                        showingSuccessAlert = true
                                        onEventUpdated?()
                                    }
                                }
                            }
                        )
                    ] : []
                )
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshEventData(eventId: event.id)
        }
    }
    
    private var notGoingAttendeesList: some View {
        List {
            ForEach(viewModel.notGoingAttendees) { attendee in
                AttendeeRowView(
                    attendee: attendee,
                    status: "Not Going",
                    statusColor: .red,
                    actions: canManageEvent ? [
                        AttendeeAction(
                            title: "Move to Waitlist",
                            color: .orange,
                            action: {
                                Task {
                                    isPerformingAction = true
                                    let success = await viewModel.moveToWaitlist(eventId: event.id, userId: attendee.id)
                                    isPerformingAction = false
                                    if success {
                                        successMessage = "User moved to waitlist successfully"
                                        showingSuccessAlert = true
                                        onEventUpdated?()
                                    }
                                }
                            }
                        )
                    ] : []
                )
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshEventData(eventId: event.id)
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .overlay(
            isPerformingAction ? 
            ProgressView("Processing...")
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(10)
            : nil
        )
        .onAppear {
            viewModel.loadEventAttendees(event: event)
        }
    }
}

// MARK: - Supporting Views

struct AttendeeRowView: View {
    let attendee: User
    let status: String
    let statusColor: Color
    let actions: [AttendeeAction]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(attendee.firstName) \(attendee.lastName)")
                    .font(.headline)
                    .fontWeight(.medium)
                
                // Email removed for privacy
                
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Menu {
                ForEach(actions) { action in
                    Button(action.title) {
                        action.action()
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AttendeeAction: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
    let action: () -> Void
}

// MARK: - ViewModel

class EventAttendeeManagementViewModel: ObservableObject {
    @Published var goingAttendees: [User] = []
    @Published var waitlistAttendees: [User] = []
    @Published var notGoingAttendees: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    @MainActor
    func loadEventAttendees(event: Event) {
        // Use the data already available in the Event object
        goingAttendees = event.goingList ?? []
        waitlistAttendees = event.waitlist ?? []
        notGoingAttendees = event.noGoList ?? []
        
        isLoading = false
    }
    
    @MainActor
    func refreshEventData(eventId: String) async {
        isLoading = true
        
        do {
            let response = try await apiService.getEvent(id: eventId)
            goingAttendees = response.data.event.goingList ?? []
            waitlistAttendees = response.data.event.waitlist ?? []
            notGoingAttendees = response.data.event.noGoList ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func approveAttendee(eventId: String, userId: String) async -> Bool {
        do {
            _ = try await apiService.approveEventAttendee(eventId: eventId, userId: userId)
            await refreshEventData(eventId: eventId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    func rejectAttendee(eventId: String, userId: String) async -> Bool {
        do {
            _ = try await apiService.rejectEventAttendee(eventId: eventId, userId: userId)
            await refreshEventData(eventId: eventId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    func moveToWaitlist(eventId: String, userId: String) async -> Bool {
        do {
            _ = try await apiService.moveToWaitlist(eventId: eventId, userId: userId)
            await refreshEventData(eventId: eventId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

// MARK: - Preview

struct EventAttendeeManagementView_Previews: PreviewProvider {
    static var previews: some View {
        EventAttendeeManagementView(event: Event.sampleEvent)
    }
}
