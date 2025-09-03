import SwiftUI

struct EventsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = EventsViewModel()
    @State private var showCreateEvent = false
    @State private var searchText = ""
    @State private var selectedEvent: Event?
    @State private var showEventDetail = false
    @State private var showEventAttendeeManagement = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Text("Events")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                if authManager.currentUser?.canCreateEvents == true {
                    Button(action: { showCreateEvent = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Search and Filter Bar
            searchAndFilterBar
            
            // Events List
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.events.isEmpty {
                emptyStateView
            } else {
                eventsList
            }
        }
        .background(Color.appBackground)
        .refreshable {
            await viewModel.loadEvents()
        }
        .task {
            await viewModel.loadEvents()
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEventDetail) {
            if let event = selectedEvent {
                EventDetailView(event: event)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showEventAttendeeManagement) {
            if let event = selectedEvent {
                EventAttendeeManagementView(event: event)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .searchable(text: $searchText, prompt: "Search events...")
        .onChange(of: searchText) { _ in
            viewModel.filterEvents(searchText: searchText)
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: AppSpacing.sm) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    FilterPill(
                        title: "All",
                        isSelected: viewModel.selectedFilter == .all,
                        action: { viewModel.selectedFilter = .all }
                    )
                    
                    FilterPill(
                        title: "Upcoming",
                        isSelected: viewModel.selectedFilter == .upcoming,
                        action: { viewModel.selectedFilter = .upcoming }
                    )
                    
                    FilterPill(
                        title: "Past",
                        isSelected: viewModel.selectedFilter == .past,
                        action: { viewModel.selectedFilter = .past }
                    )
                    
                    if authManager.currentUser?.isAdmin == true {
                        FilterPill(
                            title: "My Events",
                            isSelected: viewModel.selectedFilter == .myEvents,
                            action: { viewModel.selectedFilter = .myEvents }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .background(Color.appSurface)
    }
    
    private var eventsList: some View {
        List {
            ForEach(viewModel.filteredEvents) { event in
                EventCardView(
                    event: event,
                    onTap: {
                        selectedEvent = event
                        showEventDetail = true
                    },
                    onNotGoing: {
                        Task {
                            await notGoingToEvent(eventId: event.id)
                        }
                    },
                    onViewAttendees: {
                        selectedEvent = event
                        showEventAttendeeManagement = true
                    },
                    onEdit: {
                        selectedEvent = event
                        // TODO: Navigate to edit event view
                    },
                    onDelete: {
                        Task {
                            await deleteEvent(eventId: event.id)
                        }
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: AppSpacing.sm, leading: AppSpacing.lg, bottom: AppSpacing.sm, trailing: AppSpacing.lg))
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.appBackground)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(Color.appTextSecondary)
            
            Text("No events found")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            Text("Create your first event to get started")
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
            
            if authManager.currentUser?.canCreateEvents == true {
                AppButton(title: "Create Event", action: {
                    showCreateEvent = true
                })
                .frame(maxWidth: 200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
    
    private func notGoingToEvent(eventId: String) async {
        do {
            let success = try await APIService.shared.rejectEventAttendee(
                eventId: eventId,
                userId: authManager.currentUser?.id ?? ""
            )
            if success.success {
                await viewModel.loadEvents()
            }
        } catch {
            print("Error marking as not going: \(error)")
        }
    }
    
    private func deleteEvent(eventId: String) async {
        do {
            let success = try await APIService.shared.deleteEvent(id: eventId)
            if success.success {
                await viewModel.loadEvents()
            }
        } catch {
            print("Error deleting event: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.body2)
                .foregroundColor(isSelected ? .white : Color.appTextPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? Color.appPrimary : Color.grey100)
                .cornerRadius(AppCornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventCardView: View {
    @EnvironmentObject var authManager: AuthManager
    let event: Event
    let onTap: () -> Void
    let onNotGoing: () -> Void
    let onViewAttendees: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header with status tag
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(event.title)
                            .font(AppTypography.h5)
                            .foregroundColor(Color.appTextPrimary)
                            .lineLimit(2)
                        
                        if let description = event.description {
                            Text(description)
                                .font(AppTypography.body2)
                                .foregroundColor(Color.appTextSecondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    // Status tag (top right)
                    StatusTag(eventStatusText, color: eventStatusColor)
                }
                
                // Event details
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    EventDetailItem(
                        icon: "clock",
                        text: "\(event.formattedDate) • \(event.formattedTime)"
                    )
                    
                    if let location = event.location {
                        EventDetailItem(
                            icon: "location",
                            text: location
                        )
                    }
                    
                    // Attendees info
                    EventDetailItem(
                        icon: "person.2",
                        text: attendeesText
                    )
                }
                
                // Action buttons
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ActionButton(
                        title: "Not Going",
                        icon: "xmark",
                        color: Color.statusNotGoing
                    ) {
                        onNotGoing()
                    }
                    
                    ActionButton(
                        title: "View Attendees",
                        icon: "eye",
                        color: Color.appTextPrimary
                    ) {
                        onViewAttendees()
                    }
                }
                
                // Admin actions (if user is admin)
                if authManager.currentUser?.isAdmin == true {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            onEdit()
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            onDelete()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(Color.statusNotGoing)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(Color.appSurface)
            .cornerRadius(AppCornerRadius.large)
            .appShadow(AppShadows.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var eventStatusText: String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let eventDate = formatter.date(from: event.date) else {
            return "Unknown"
        }
        
        if eventDate < today {
            return "Past"
        } else if Calendar.current.isDate(eventDate, inSameDayAs: today) {
            return "Today"
        } else {
            return "Going" // Default status for upcoming events
        }
    }
    
    private var eventStatusColor: Color {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let eventDate = formatter.date(from: event.date) else {
            return Color.grey600
        }
        
        if eventDate < today {
            return Color.grey600
        } else if Calendar.current.isDate(eventDate, inSameDayAs: today) {
            return Color.statusGoing
        } else {
            return Color.statusGoing
        }
    }
    
    private var attendeesText: String {
        let goingCount = event.goingList?.count ?? 0
        let waitlistCount = event.noGoList?.count ?? 0
        let total = goingCount + waitlistCount
        
        if total == 0 {
            return "0 total (0 going) • 0 waitlisted"
        } else {
            return "\(total) total (\(goingCount) going) • \(waitlistCount) waitlisted"
        }
    }
}

struct EventDetailItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color.appTextSecondary)
            
            Text(text)
                .font(AppTypography.caption)
                .foregroundColor(Color.appTextSecondary)
                .lineLimit(1)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(color)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EventsView()
        .environmentObject(AuthManager.shared)
}
