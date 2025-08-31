import SwiftUI

struct EventAttendeeManagementView: View {
    let event: Event
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = EventAttendeeManagementViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
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
            }
            .navigationTitle("Attendee Management")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Attendee Management")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadEventAttendees(eventId: event.id)
                }
            }
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
                    actions: [
                        AttendeeAction(
                            title: "Move to Waitlist",
                            color: .orange,
                            action: {
                                Task {
                                    await viewModel.moveToWaitlist(eventId: event.id, userId: attendee.id)
                                }
                            }
                        ),
                        AttendeeAction(
                            title: "Mark Not Going",
                            color: .red,
                            action: {
                                Task {
                                    await viewModel.rejectAttendee(eventId: event.id, userId: attendee.id)
                                }
                            }
                        )
                    ]
                )
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.loadEventAttendees(eventId: event.id)
        }
    }
    
    private var waitlistAttendeesList: some View {
        List {
            ForEach(viewModel.waitlistAttendees) { attendee in
                AttendeeRowView(
                    attendee: attendee,
                    status: "Waitlist",
                    statusColor: .orange,
                    actions: [
                        AttendeeAction(
                            title: "Approve",
                            color: .green,
                            action: {
                                Task {
                                    await viewModel.approveAttendee(eventId: event.id, userId: attendee.id)
                                }
                            }
                        ),
                        AttendeeAction(
                            title: "Mark Not Going",
                            color: .red,
                            action: {
                                Task {
                                    await viewModel.rejectAttendee(eventId: event.id, userId: attendee.id)
                                }
                            }
                        )
                    ]
                )
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.loadEventAttendees(eventId: event.id)
        }
    }
    
    private var notGoingAttendeesList: some View {
        List {
            ForEach(viewModel.notGoingAttendees) { attendee in
                AttendeeRowView(
                    attendee: attendee,
                    status: "Not Going",
                    statusColor: .red,
                    actions: [
                        AttendeeAction(
                            title: "Move to Waitlist",
                            color: .orange,
                            action: {
                                Task {
                                    await viewModel.moveToWaitlist(eventId: event.id, userId: attendee.id)
                                }
                            }
                        )
                    ]
                )
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.loadEventAttendees(eventId: event.id)
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
                
                Text(attendee.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
    func loadEventAttendees(eventId: String) async {
        isLoading = true
        
        do {
            let response = try await apiService.getEventAttendees(eventId: eventId)
            // Note: This endpoint only returns confirmed attendees
            // For full management, we'd need separate endpoints for waitlist and not-going
            goingAttendees = response.data.attendees
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func approveAttendee(eventId: String, userId: String) async {
        do {
            _ = try await apiService.approveEventAttendee(eventId: eventId, userId: userId)
            await loadEventAttendees(eventId: eventId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func rejectAttendee(eventId: String, userId: String) async {
        do {
            _ = try await apiService.rejectEventAttendee(eventId: eventId, userId: userId)
            await loadEventAttendees(eventId: eventId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func moveToWaitlist(eventId: String, userId: String) async {
        do {
            _ = try await apiService.moveToWaitlist(eventId: eventId, userId: userId)
            await loadEventAttendees(eventId: eventId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

struct EventAttendeeManagementView_Previews: PreviewProvider {
    static var previews: some View {
        EventAttendeeManagementView(event: Event.sampleEvent)
    }
}
