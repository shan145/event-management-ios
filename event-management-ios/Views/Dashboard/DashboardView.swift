import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Welcome Header
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Welcome back, \(authManager.currentUser?.firstName ?? "Anonymous")")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                    .fontWeight(.bold)
                
                Text("Manage your groups and events, join waitlists, and stay connected with your community.")
                    .font(AppTypography.body2)
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            
            // Navigation Tabs
            HStack(spacing: 0) {
                Button(action: { selectedTab = 0 }) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "person.3")
                            .font(.system(size: 16))
                        Text("My Groups")
                            .font(AppTypography.body1)
                            .fontWeight(selectedTab == 0 ? .bold : .regular)
                    }
                    .foregroundColor(selectedTab == 0 ? Color.appTextPrimary : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                }
                
                Button(action: { selectedTab = 1 }) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                        Text("My Events")
                            .font(AppTypography.body1)
                            .fontWeight(selectedTab == 1 ? .bold : .regular)
                    }
                    .foregroundColor(selectedTab == 1 ? Color.appTextPrimary : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            
            // Divider
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.grey200)
                .padding(.horizontal, AppSpacing.lg)
            
            // Tab Content
            if selectedTab == 0 {
                GroupsTabView(viewModel: viewModel)
            } else {
                EventsTabView(viewModel: viewModel)
            }
        }
        .background(Color.appBackground)
        .task {
            await viewModel.loadDashboardData()
        }
        .refreshable {
            await viewModel.loadDashboardData()
        }
    }
}

// MARK: - Groups Tab View
struct GroupsTabView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
            HStack {
                Text("My Groups")
                    .font(AppTypography.h4)
                    .foregroundColor(Color.appTextPrimary)
                        .fontWeight(.bold)
                
                Spacer()
                
                    Text("\(viewModel.myGroups.count) groups")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                
                // Groups List
                if viewModel.isLoading {
                    LoadingView()
                        .frame(height: 200)
                } else if viewModel.myGroups.isEmpty {
                emptyStateView(
                    icon: "person.3",
                    title: "No groups yet",
                    message: "Join a group to start managing events"
                )
            } else {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(viewModel.myGroups) { group in
                            DashboardGroupCardView(group: group) {
                                Task { await viewModel.loadDashboardData() }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color.appTextSecondary)
            
            Text(title)
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            Text(message)
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
    }
}

// MARK: - Events Tab View
struct EventsTabView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                HStack {
                    Text("My Events")
                        .font(AppTypography.h4)
                        .foregroundColor(Color.appTextPrimary)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(viewModel.upcomingEvents.count) event\(viewModel.upcomingEvents.count == 1 ? "" : "s")")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                
                // Events List
                if viewModel.isLoading {
                    LoadingView()
                        .frame(height: 200)
                } else if viewModel.upcomingEvents.isEmpty {
                    emptyStateView(
                        icon: "calendar",
                        title: "No upcoming events",
                        message: "You don't have any events scheduled"
                    )
                } else {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(viewModel.upcomingEvents) { event in
                            DashboardEventCardView(event: event) {
                                // Refresh the data when event is updated
                                Task {
                                    await viewModel.loadDashboardData()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color.appTextSecondary)
            
            Text(title)
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            Text(message)
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
    }
}

// MARK: - Dashboard-Specific Card Views

struct DashboardGroupCardView: View {
    let group: Group
    @EnvironmentObject var authManager: AuthManager
    let onGroupUpdated: (() -> Void)?
    
    init(group: Group, onGroupUpdated: (() -> Void)? = nil) {
        self.group = group
        self.onGroupUpdated = onGroupUpdated
    }
    
    // Modal states
    @State private var showingCreateEvent = false
    @State private var showingInviteMembers = false
    @State private var showingManageMembers = false
    @State private var showingGroupDetail = false
    @State private var showingLeaveAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header with title and admin tag
            HStack {
                Text(group.name)
                    .font(AppTypography.h4)
                    .foregroundColor(Color.appTextPrimary)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isGroupAdmin {
                    StatusTag("Group Admin", color: Color.statusAdmin)
                }
            }
            
            // Group details
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "person.3")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appTextSecondary)
                    Text("\(group.memberCount) members")
                        .font(AppTypography.body1)
                        .foregroundColor(Color.appTextSecondary)
                }
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appTextSecondary)
                    Text("\(group.totalEventCount) events")
                        .font(AppTypography.body1)
                        .foregroundColor(Color.appTextSecondary)
                }
            }
            
            // Group tag if exists
            if let tags = group.tags, !tags.isEmpty {
                HStack {
                    ForEach(tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(AppTypography.body2)
                            .foregroundColor(Color.appTextPrimary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(Color.grey100)
                            .cornerRadius(AppCornerRadius.large)
                    }
                    Spacer()
                }
            }
            
            // Actions
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // View Members (always shown)
                Button(action: {
                    showingGroupDetail = true
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "eye")
                            .font(.system(size: 16))
                        Text("View Members")
                            .font(AppTypography.body1)
                    }
                    .foregroundColor(Color.appTextPrimary)
                }
                .buttonStyle(PlainButtonStyle())
                
                if isGroupAdmin {
                    // Admin actions for group admins
                    Button(action: {
                        showingCreateEvent = true
                    }) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 16))
                            Text("Add Event")
                                .font(AppTypography.body1)
                        }
                        .foregroundColor(Color.appTextPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingInviteMembers = true
                    }) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                            Text("Invite")
                                .font(AppTypography.body1)
                        }
                        .foregroundColor(Color.appTextPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingManageMembers = true
                    }) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "person.2")
                                .font(.system(size: 16))
                            Text("Manage Members")
                                .font(AppTypography.body1)
                        }
                        .foregroundColor(Color.appPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Leave group for non-admins
                    Button(action: {
                        showingLeaveAlert = true
                    }) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16))
                            Text("Leave Group")
                                .font(AppTypography.body1)
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView(preSelectedGroup: group)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingInviteMembers) {
            InviteMembersView(group: group)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingManageMembers) {
            GroupAdminView(group: group)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingGroupDetail) {
            GroupDetailView(group: group) {
                onGroupUpdated?()
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Leave Group", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await leaveGroup()
                }
            }
        } message: {
            Text("Are you sure you want to leave \"\(group.name)\"? You will need to be re-invited to rejoin.")
        }
    }
    
    private var isGroupAdmin: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        // Check if user is super admin or admin of THIS specific group
        return currentUser.isAdminOfGroup(group.id)
    }
    
    private func leaveGroup() async {
        do {
            let response = try await APIService.shared.leaveGroup(groupId: group.id)
            await MainActor.run {
                print("✅ Successfully left group: \(response.message ?? "Success")")
                // Refresh the parent view to remove this group from the list
                onGroupUpdated?()
            }
        } catch {
            await MainActor.run {
                print("❌ Failed to leave group: \(error)")
                // TODO: Show error to user
            }
        }
    }
}

struct DashboardEventCardView: View {
    let event: Event
    @EnvironmentObject var authManager: AuthManager
    let onEventUpdated: (() -> Void)?
    
    // Modal states
    @State private var showingEditEvent = false
    @State private var showingAttendees = false
    @State private var showingDeleteAlert = false
    @State private var isJoiningWaitlist = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header with title and status
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(event.title)
                        .font(AppTypography.h4)
                        .foregroundColor(Color.appTextPrimary)
                        .fontWeight(.bold)
                    
                    if let description = event.description, !description.isEmpty {
                        Text(description)
                            .font(AppTypography.body1)
                            .foregroundColor(Color.appTextSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Status tag based on user's RSVP
                if let status = getUserEventStatus() {
                    StatusTag(status, color: getStatusColor(status))
                }
            }
            
            // Event details
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appTextSecondary)
                    Text(event.formattedDateTime)
                        .font(AppTypography.body1)
                        .foregroundColor(Color.appTextSecondary)
                }
                
                if let location = event.location, !location.name.isEmpty {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "mappin")
                            .font(.system(size: 16))
                            .foregroundColor(Color.appTextSecondary)
                        Text(location.name)
                            .font(AppTypography.body1)
                            .foregroundColor(Color.appTextSecondary)
                    }
                }
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "person.3")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appTextSecondary)
                    Text("\(getTotalAttendees()) total (\(getGoingCount()) going)")
                        .font(AppTypography.body1)
                        .foregroundColor(Color.appTextSecondary)
                }
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "clock.badge")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appTextSecondary)
                    Text("\(getWaitlistCount()) waitlisted")
                        .font(AppTypography.body1)
                        .foregroundColor(Color.appTextSecondary)
                }
            }
            
            Spacer(minLength: AppSpacing.lg)
            
            // Actions
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Button(action: {
                    Task {
                        await joinWaitlist()
                    }
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        if isJoiningWaitlist {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16))
                        }
                        Text(isJoiningWaitlist ? "Joining..." : "Join Waitlist")
                            .font(AppTypography.body1)
                    }
                    .foregroundColor(Color.appTextPrimary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isJoiningWaitlist)
                
                Button(action: {
                    showingAttendees = true
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "eye")
                            .font(.system(size: 16))
                        Text("View Attendees")
                            .font(AppTypography.body1)
                    }
                    .foregroundColor(Color.appTextPrimary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Admin actions for event creators/admins
            if canEditEvent() {
                HStack(spacing: AppSpacing.sm) {
                    Spacer()
                    
                    Button(action: {
                        showingEditEvent = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(Color.appTextPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
        .sheet(isPresented: $showingEditEvent) {
            EditEventView(event: event) {
                onEventUpdated?()
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAttendees) {
            EventAttendeeManagementView(event: event) {
                onEventUpdated?()
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
    }
    
    private func getUserEventStatus() -> String? {
        guard let currentUser = authManager.currentUser else { return nil }
        
        if event.goingList?.contains(where: { $0.id == currentUser.id }) == true {
            return "Going"
        } else if event.waitlist?.contains(where: { $0.id == currentUser.id }) == true {
            return "Waitlisted"
        } else if event.noGoList?.contains(where: { $0.id == currentUser.id }) == true {
            return "Not Going"
        }
        
        return nil
    }
    
    private func getStatusColor(_ status: String) -> Color {
        switch status {
        case "Going":
            return Color.statusGoing
        case "Waitlisted":
            return Color.statusWaitlisted
        case "Not Going":
            return Color.statusNotGoing
        default:
            return Color.appTextSecondary
        }
    }
    
    private func getTotalAttendees() -> Int {
        let going = event.goingList?.count ?? 0
        let waitlisted = event.waitlist?.count ?? 0
        return going + waitlisted
    }
    
    private func getGoingCount() -> Int {
        return event.goingList?.count ?? 0
    }
    
    private func getWaitlistCount() -> Int {
        return event.waitlist?.count ?? 0
    }
    
    private func canEditEvent() -> Bool {
        guard let currentUser = authManager.currentUser else { return false }
        return currentUser.isAdmin || currentUser.isGroupAdmin
    }
    
    private func joinWaitlist() async {
        isJoiningWaitlist = true
        
        do {
            let response = try await APIService.shared.joinEventWaitlist(id: event.id)
            await MainActor.run {
                print("✅ Joined waitlist successfully: \(response.message ?? "Success")")
                // Refresh the parent view
                onEventUpdated?()
            }
        } catch {
            await MainActor.run {
                print("❌ Failed to join waitlist: \(error)")
                // TODO: Show error alert to user
            }
        }
        
        isJoiningWaitlist = false
    }
    
    private func deleteEvent() {
        Task {
            do {
                let response = try await APIService.shared.deleteEvent(id: event.id)
                await MainActor.run {
                    print("✅ Event deleted successfully: \(response.message ?? "Success")")
                    // Refresh the parent view
                    onEventUpdated?()
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to delete event: \(error)")
                    // TODO: Show error alert to user
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}
