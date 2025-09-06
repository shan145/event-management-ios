import SwiftUI
import UIKit

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
    @State private var showingGroupEvents = false
    @State private var showingLeaveAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header with title and admin tag
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .lineLimit(2)
                    
                    if let tags = group.tags, !tags.isEmpty {
                        Text(tags.prefix(2).joined(separator: " • "))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(Color.grey600)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isGroupAdmin {
                    StatusTag("Admin", color: Color.statusAdmin, style: .soft)
                }
            }
            
            // Group details with modern styling
            HStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(group.memberCount)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                    Text("members")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.grey500)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(group.totalEventCount)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                    Text("events")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.grey500)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                Spacer()
            }
            
            // Actions with uniform width
            VStack(spacing: AppSpacing.sm) {
                // View Members (always shown)
                Button(action: {
                    showingGroupDetail = true
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "eye")
                            .font(.system(size: 16))
                        Text("View Members")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                    }
                }
                .buttonStyle(ModernCardButtonStyle())
                .frame(maxWidth: .infinity)
                
                // View Events (always shown for all users)
                Button(action: {
                    showingGroupEvents = true
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                        Text("View Events")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                    }
                }
                .buttonStyle(ModernCardButtonStyle())
                .frame(maxWidth: .infinity)
                
                if isGroupAdmin {
                    // Admin actions for group admins - all in consistent black/white style
                    Button(action: {
                        showingCreateEvent = true
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "plus")
                                .font(.system(size: 16))
                            Text("Add Event")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                        }
                    }
                    .buttonStyle(ModernCardButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        showingInviteMembers = true
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                            Text("Invite Members")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                        }
                    }
                    .buttonStyle(ModernCardButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        showingManageMembers = true
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "person.2.badge.gearshape")
                                .font(.system(size: 16))
                            Text("Manage Members")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                        }
                    }
                    .buttonStyle(ModernCardButtonStyle())
                    .frame(maxWidth: .infinity)
                } else {
                    // Leave group for non-admins - keep red for destructive action
                    Button(action: {
                        showingLeaveAlert = true
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 16))
                            Text("Leave Group")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                        }
                    }
                    .buttonStyle(ModernActionButtonStyle(color: Color.statusNotGoing, isDestructive: true))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(AppSpacing.xl)
        .modernCardStyle()
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView(preSelectedGroup: group) {
                // Refresh the parent view when event is successfully created
                onGroupUpdated?()
            }
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
        .sheet(isPresented: $showingGroupEvents) {
            GroupEventsListView(group: group)
                .presentationDetents([.medium, .large])
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
    @State private var showingNotGoingAlert = false
    @State private var showingDuplicateEvent = false
    @State private var showingEmailAttendees = false
    @State private var isJoiningWaitlist = false
    @State private var isMarkingNotGoing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header with title and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Group indicator
                    if let groupName = event.groupId.name {
                        Text(groupName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.statusAdmin)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    
                    Text(event.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .lineLimit(2)
                    
                    if let description = event.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(Color.grey600)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Status tag based on user's RSVP
                if let status = getUserEventStatus() {
                    StatusTag(status, color: getStatusColor(status), style: .soft)
                }
            }
            
            // Event details with modern layout
            VStack(spacing: AppSpacing.md) {
                // Date and Time
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(Color.statusAdmin)
                        .frame(width: 24)
                    
                    Text(event.formattedDateTime)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                    
                    Spacer()
                }
                
                // Location if exists
                if let location = event.location, !location.name.isEmpty {
                    Button(action: {
                        openLocationInMaps(location: location.name)
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "mappin.circle")
                                .font(.system(size: 18))
                                .foregroundColor(Color.statusNotGoing)
                                .frame(width: 24)
                            
                            Text(location.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.appTextPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                                .foregroundColor(Color.grey400)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Attendance stats
                HStack(spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(getGoingCount())")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.statusGoing)
                        Text("attending")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.grey500)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(getWaitlistCount())")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.statusWaitlisted)
                        Text("waitlisted")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.grey500)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    
                    if getTotalAttendees() > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(getTotalAttendees())")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.appTextPrimary)
                            Text("total")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color.grey500)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            Spacer(minLength: AppSpacing.lg)
            
            // Actions with uniform width
            VStack(spacing: AppSpacing.sm) {
                // Show appropriate button based on user's current status
                if shouldShowJoinWaitlistButton() {
                    Button(action: {
                        Task {
                            await joinWaitlist()
                        }
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            if isJoiningWaitlist {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 16))
                            }
                            Text(isJoiningWaitlist ? "Joining..." : "Join Waitlist")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                        }
                    }
                    .buttonStyle(ModernActionButtonStyle(color: Color.statusWaitlisted))
                    .disabled(isJoiningWaitlist)
                    .frame(maxWidth: .infinity)
                } else {
                    Button(action: {
                        showingNotGoingAlert = true
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            if isMarkingNotGoing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 16))
                            }
                            Text(isMarkingNotGoing ? "Updating..." : "Not Going")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                        }
                    }
                    .buttonStyle(ModernActionButtonStyle(color: Color.statusNotGoing))
                    .disabled(isMarkingNotGoing)
                    .frame(maxWidth: .infinity)
                }
                
                Button(action: {
                    showingAttendees = true
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "eye")
                            .font(.system(size: 16))
                        Text("View Attendees")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                    }
                }
                .buttonStyle(ModernCardButtonStyle())
                .frame(maxWidth: .infinity)
            }
            
            // Admin actions for event creators/admins
            if canEditEvent() {
                HStack(spacing: AppSpacing.md) {
                    Spacer()
                    
                    Button(action: {
                        showingDuplicateEvent = true
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.appPrimary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        showingEmailAttendees = true
                    }) {
                        Image(systemName: "envelope")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.statusAdmin)
                            .frame(width: 40, height: 40)
                            .background(Color.statusAdmin.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        showingEditEvent = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appTextPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.grey100)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.statusNotGoing)
                            .frame(width: 40, height: 40)
                            .background(Color.statusNotGoing.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.xl)
        .modernCardStyle()
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
        .sheet(isPresented: $showingDuplicateEvent) {
            CreateEventView(eventToDuplicate: event) {
                // Refresh the parent view when event is successfully created
                onEventUpdated?()
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEmailAttendees) {
            EventEmailView(event: event)
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
        .alert("Mark as Not Going", isPresented: $showingNotGoingAlert) {
            Button("Not Going", role: .destructive) {
                Task {
                    await markNotGoing()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to mark yourself as not going to this event?")
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
    
    private func shouldShowJoinWaitlistButton() -> Bool {
        // Show "Join Waitlist" if user has not responded or is marked as "Not Going"
        let userStatus = getUserEventStatus()
        return userStatus == nil || userStatus == "Not Going"
    }
    
    private func openLocationInMaps(location: String) {
        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mapsURL = URL(string: "maps://?q=\(encodedLocation)")
        let webURL = URL(string: "https://maps.google.com/maps?q=\(encodedLocation)")
        
        if let mapsURL = mapsURL, UIApplication.shared.canOpenURL(mapsURL) {
            // Open in Apple Maps if available
            UIApplication.shared.open(mapsURL)
        } else if let webURL = webURL {
            // Fallback to Google Maps in browser
            UIApplication.shared.open(webURL)
        }
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
    
    private func markNotGoing() async {
        isMarkingNotGoing = true
        
        do {
            let response = try await APIService.shared.markEventNotGoing(id: event.id)
            await MainActor.run {
                print("✅ Marked as not going successfully: \(response.message ?? "Success")")
                // Refresh the parent view
                onEventUpdated?()
            }
        } catch {
            await MainActor.run {
                print("❌ Failed to mark as not going: \(error)")
                // TODO: Show error alert to user
            }
        }
        
        isMarkingNotGoing = false
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

// MARK: - Group Events List View

struct GroupEventsListView: View {
    let group: Group
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    HStack {
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(TextButtonStyle())
                        
                        Spacer()
                        
                        Text("\(group.name) Events")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.appTextPrimary)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Button("") { }
                            .buttonStyle(TextButtonStyle())
                            .disabled(true)
                            .opacity(0)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    
                    Divider()
                        .background(Color.appDivider)
                }
                .background(Color.appSurface)
                
                // Events List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading events...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.grey600)
                    Spacer()
                } else if groupEvents.isEmpty {
                    emptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(groupEvents) { event in
                                EventRowView(event: event)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.lg)
                    }
                    .background(Color.appBackground)
                }
            }
        }
        .task {
            await viewModel.loadDashboardData()
        }
    }
    
    private var groupEvents: [Event] {
        return viewModel.upcomingEvents
            .filter { $0.groupId.id == group.id }
            .sorted { event1, event2 in
                // Sort by date chronologically
                let date1 = parseEventDate(event1)
                let date2 = parseEventDate(event2)
                return date1 < date2
            }
    }
    
    private func parseEventDate(_ event: Event) -> Date {
        // First, try to use the existing formattedDateTime from the Event model if available
        let eventDateTimeString = event.formattedDateTime
        
        // Try parsing the server's formatted datetime directly
        let etTimeZone = TimeZone(identifier: "America/New_York")!
        
        // Try multiple parsing strategies
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = etTimeZone
        
        // Strategy 1: Parse using event.formattedDateTime if it looks like a formatted string
        if eventDateTimeString.contains(",") && eventDateTimeString.contains("ET") {
            dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
            let cleanedString = eventDateTimeString.replacingOccurrences(of: " ET", with: "")
            if let parsedDate = dateFormatter.date(from: cleanedString) {
                return parsedDate
            }
        }
        
        // Strategy 2: Combine date and time strings directly (assuming they're in UTC or ET)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let combinedString = "\(event.date) \(event.time)"
        if let parsedDate = dateFormatter.date(from: combinedString) {
            return parsedDate
        }
        
        // Strategy 3: Parse separately and combine
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = etTimeZone
        
        if let parsedDate = dateFormatter.date(from: event.date) {
            dateFormatter.dateFormat = "HH:mm"
            if let parsedTime = dateFormatter.date(from: event.time) {
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: parsedDate)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: parsedTime)
                
                var combinedComponents = DateComponents()
                combinedComponents.year = dateComponents.year
                combinedComponents.month = dateComponents.month
                combinedComponents.day = dateComponents.day
                combinedComponents.hour = timeComponents.hour
                combinedComponents.minute = timeComponents.minute
                combinedComponents.timeZone = etTimeZone
                
                if let combinedDate = calendar.date(from: combinedComponents) {
                    return combinedDate
                }
            }
            return parsedDate
        }
        
        // Last resort
        print("⚠️ Failed to parse event date: '\(event.date)' and time: '\(event.time)', formattedDateTime: '\(eventDateTimeString)'")
        return Date()
    }
    
    private func emptyStateView() -> some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(Color.grey400)
            
            VStack(spacing: AppSpacing.sm) {
                Text("No Events")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                
                Text("This group doesn't have any upcoming events yet.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Color.grey600)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xxl)
        .background(Color.appBackground)
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Date indicator
            VStack(spacing: 2) {
                Text(formattedMonth)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.statusAdmin)
                    .textCase(.uppercase)
                
                Text(formattedDay)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
            }
            .frame(width: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(2)
                
                Text(formattedTime)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.grey600)
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var formattedMonth: String {
        let eventDate = parseEventDate()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        
        return dateFormatter.string(from: eventDate)
    }
    
    private var formattedDay: String {
        let eventDate = parseEventDate()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        
        return dateFormatter.string(from: eventDate)
    }
    
    private var formattedTime: String {
        let eventDate = parseEventDate()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        
        return dateFormatter.string(from: eventDate)
    }
    
    private func parseEventDate() -> Date {
        // First, try to use the existing formattedDateTime from the Event model if available
        let eventDateTimeString = event.formattedDateTime
        
        // Try parsing the server's formatted datetime directly
        let etTimeZone = TimeZone(identifier: "America/New_York")!
        
        // Try multiple parsing strategies
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = etTimeZone
        
        // Strategy 1: Parse using event.formattedDateTime if it looks like a formatted string
        if eventDateTimeString.contains(",") && eventDateTimeString.contains("ET") {
            dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
            let cleanedString = eventDateTimeString.replacingOccurrences(of: " ET", with: "")
            if let parsedDate = dateFormatter.date(from: cleanedString) {
                return parsedDate
            }
        }
        
        // Strategy 2: Combine date and time strings directly (assuming they're in UTC or ET)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let combinedString = "\(event.date) \(event.time)"
        if let parsedDate = dateFormatter.date(from: combinedString) {
            return parsedDate
        }
        
        // Strategy 3: Parse separately and combine
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = etTimeZone
        
        if let parsedDate = dateFormatter.date(from: event.date) {
            dateFormatter.dateFormat = "HH:mm"
            if let parsedTime = dateFormatter.date(from: event.time) {
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: parsedDate)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: parsedTime)
                
                var combinedComponents = DateComponents()
                combinedComponents.year = dateComponents.year
                combinedComponents.month = dateComponents.month
                combinedComponents.day = dateComponents.day
                combinedComponents.hour = timeComponents.hour
                combinedComponents.minute = timeComponents.minute
                combinedComponents.timeZone = etTimeZone
                
                if let combinedDate = calendar.date(from: combinedComponents) {
                    return combinedDate
                }
            }
            return parsedDate
        }
        
        // Last resort
        print("⚠️ Failed to parse event date: '\(event.date)' and time: '\(event.time)', formattedDateTime: '\(eventDateTimeString)'")
        return Date()
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}
