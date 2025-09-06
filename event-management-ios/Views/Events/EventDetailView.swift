import SwiftUI

struct EventDetailView: View {
    let event: Event
    @StateObject private var viewModel = EventDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAttendeeManagement = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                eventHeader
                
                Divider()
                
                eventDescription
                eventStats
                attendeesSection
                waitlistSection
                
                Spacer(minLength: 100)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    if event.isOrganizer {
                        Button("Manage") {
                            showingAttendeeManagement = true
                        }
                        
                        Button("Edit") {
                            showingEditSheet = true
                        }
                        
                        Button("Delete") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .overlay(actionButtonsOverlay)
        .sheet(isPresented: $showingEditSheet) {
            EditEventView(event: event) {
                viewModel.loadEventDetails(eventId: event.id)
            }
        }
        .sheet(isPresented: $showingAttendeeManagement) {
            EventAttendeeManagementView(event: event)
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteEvent(eventId: event.id)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .onAppear {
            viewModel.loadEventDetails(eventId: event.id)
        }
    }
    
    // MARK: - Supporting Views
    
    private var eventHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("\(event.date) at \(event.time)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let location = event.location, !location.name.isEmpty {
                HStack {
                    Image(systemName: "mappin")
                        .foregroundColor(.green)
                    Text(location.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var eventDescription: some View {
        if let description = event.description, !description.isEmpty {
            AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var eventStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                StatCard(
                    icon: "person.2",
                                title: "Attendees",
            value: "\(event.goingList?.count ?? 0)",
                    color: .blue
                )
                
                StatCard(
                    icon: "clock",
                    title: "Waitlist",
                    value: "\(event.waitlist?.count ?? 0)",
                    color: .orange
                )
            }
            
            if let maxAttendees = event.maxAttendees {
                HStack {
                    StatCard(
                        icon: "person.3",
                        title: "Capacity",
                        value: "\(maxAttendees)",
                        color: .green
                    )
                    
                    StatCard(
                        icon: "percent",
                        title: "Full",
                        value: "\(Int((Double(event.goingList?.count ?? 0) / Double(maxAttendees)) * 100))%",
                        color: .purple
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var attendeesSection: some View {
        if let attendees = event.goingList, !attendees.isEmpty {
            AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    Text("Attendees")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(attendees, id: \.id) { attendee in
                            AttendeeRow(attendee: attendee)
                        }
                    }
                }
                .padding(.horizontal)
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var waitlistSection: some View {
        if let waitlist = event.waitlist, !waitlist.isEmpty {
            AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    Text("Waitlist")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(waitlist, id: \.id) { attendee in
                            AttendeeRow(attendee: attendee, isWaitlist: true)
                        }
                    }
                }
                .padding(.horizontal)
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var actionButtonsOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                if event.isOrganizer {
                    HStack(spacing: 12) {
                        Button("Manage Attendees") {
                            // TODO: Navigate to attendee management
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("Send Email") {
                            // TODO: Send email to attendees
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                } else {
                    if event.isAttending {
                        Button("Leave Event") {
                            Task {
                                await viewModel.leaveEvent(eventId: event.id)
                            }
                        }
                        .buttonStyle(DangerButtonStyle())
                    } else {
                        Button("Join Event") {
                            Task {
                                await viewModel.joinEvent(eventId: event.id)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.95))
            .shadow(radius: 2)
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AttendeeRow: View {
    let attendee: User
    let isWaitlist: Bool
    
    init(attendee: User, isWaitlist: Bool = false) {
        self.attendee = attendee
        self.isWaitlist = isWaitlist
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(attendee.firstName.prefix(1) + attendee.lastName.prefix(1))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(attendee.firstName) \(attendee.lastName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(attendee.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isWaitlist {
                Text("Waitlist")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}



struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EventDetailView(event: Event.sampleEvent)
        }
    }
}
