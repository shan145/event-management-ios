import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = GroupsViewModel()
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var searchText = ""
    @State private var selectedGroup: Group?
    @State private var showGroupDetail = false
    @State private var showInviteMembers = false
    @State private var showGroupAdmin = false
    @State private var showCreateEvent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Text("Groups")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu {
                    if authManager.currentUser?.canCreateGroups == true {
                        Button(action: { showCreateGroup = true }) {
                            Label("Create Group", systemImage: "plus.circle")
                        }
                    }
                    
                    Button(action: { showJoinGroup = true }) {
                        Label("Join Group", systemImage: "person.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Search and Filter Bar
            searchAndFilterBar
            
            // Groups List
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.groups.isEmpty {
                emptyStateView
            } else {
                groupsList
            }
        }
        .background(Color.appBackground)
        .refreshable {
            await viewModel.loadGroups()
        }
        .task {
            await viewModel.loadGroups()
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showGroupDetail) {
            if let group = selectedGroup {
                GroupDetailView(group: group)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showInviteMembers) {
            if let group = selectedGroup {
                InviteMembersView(group: group)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showGroupAdmin) {
            if let group = selectedGroup {
                GroupAdminView(group: group)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .searchable(text: $searchText, prompt: "Search groups...")
        .onChange(of: searchText) { _ in
            viewModel.filterGroups(searchText: searchText)
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
                        title: "My Groups",
                        isSelected: viewModel.selectedFilter == .myGroups,
                        action: { viewModel.selectedFilter = .myGroups }
                    )
                    
                    FilterPill(
                        title: "Available",
                        isSelected: viewModel.selectedFilter == .available,
                        action: { viewModel.selectedFilter = .available }
                    )
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .background(Color.appSurface)
    }
    
    private var groupsList: some View {
        List {
            ForEach(viewModel.filteredGroups) { group in
                GroupCardView(
                    group: group,
                    onTap: {
                        selectedGroup = group
                        showGroupDetail = true
                    },
                    onViewMembers: {
                        selectedGroup = group
                        showGroupDetail = true
                    },
                    onAddEvent: {
                        selectedGroup = group
                        showCreateEvent = true
                    },
                    onInvite: {
                        selectedGroup = group
                        showInviteMembers = true
                    },
                    onManageMembers: {
                        selectedGroup = group
                        showGroupAdmin = true
                    },
                    onLeaveGroup: {
                        Task {
                            await leaveGroup(groupId: group.id)
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
            Image(systemName: "person.3")
                .font(.system(size: 64))
                .foregroundColor(Color.appTextSecondary)
            
            Text("No groups found")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            Text("Create a group or join an existing one to get started")
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: AppSpacing.md) {
                if authManager.currentUser?.canCreateGroups == true {
                    AppButton(title: "Create Group", action: {
                        showCreateGroup = true
                    })
                    .frame(maxWidth: 150)
                }
                
                AppButton(title: "Join Group", action: {
                    showJoinGroup = true
                }, style: .secondary)
                .frame(maxWidth: 150)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
    
    private func leaveGroup(groupId: String) async {
        do {
            let success = try await APIService.shared.removeGroupMember(
                userId: authManager.currentUser?.id ?? "",
                groupId: groupId
            )
            if success.success {
                await viewModel.loadGroups()
            }
        } catch {
            print("Error leaving group: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct GroupCardView: View {
    @EnvironmentObject var authManager: AuthManager
    let group: Group
    let onTap: () -> Void
    let onViewMembers: () -> Void
    let onAddEvent: () -> Void
    let onInvite: () -> Void
    let onManageMembers: () -> Void
    let onLeaveGroup: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header with status tag
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(group.name)
                            .font(AppTypography.h5)
                            .foregroundColor(Color.appTextPrimary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Status tag (Group Admin if user is admin of this group)
                    if authManager.currentUser?.isAdminOfGroup(group.id) == true {
                        StatusTag("Group Admin", color: Color.statusAdmin)
                    }
                }
                
                // Group stats
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    GroupStatItem(
                        icon: "person.2",
                        text: "\(group.memberCount) members"
                    )
                    
                    GroupStatItem(
                        icon: "calendar",
                        text: "\(group.eventCount ?? 0) events"
                    )
                    
                    // Tags
                    if let tags = group.tags, !tags.isEmpty {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(AppTypography.caption)
                                    .foregroundColor(Color.appTextSecondary)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(Color.grey100)
                                    .cornerRadius(AppCornerRadius.large)
                            }
                        }
                    }
                }
                
                // Action buttons
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ActionButton(
                        title: "View Members",
                        icon: "eye",
                        color: Color.appTextPrimary
                    ) {
                        onViewMembers()
                    }
                    
                    if authManager.currentUser?.isAdminOfGroup(group.id) == true {
                        ActionButton(
                            title: "Add Event",
                            icon: "plus",
                            color: Color.appTextPrimary
                        ) {
                            onAddEvent()
                        }
                        
                        ActionButton(
                            title: "Invite",
                            icon: "square.and.arrow.up",
                            color: Color.appTextPrimary
                        ) {
                            onInvite()
                        }
                        
                        ActionButton(
                            title: "Send Message",
                            icon: "envelope",
                            color: Color.appTextPrimary
                        ) {
                            // TODO: Implement send message action (could open a messaging view)
                        }
                        
                        ActionButton(
                            title: "Manage Members",
                            icon: "person.2",
                            color: Color.statusAdmin
                        ) {
                            onManageMembers()
                        }
                    } else {
                        ActionButton(
                            title: "Leave Group",
                            icon: "arrow.right.square",
                            color: Color.statusNotGoing
                        ) {
                            onLeaveGroup()
                        }
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
}

struct GroupStatItem: View {
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
        }
    }
}

#Preview {
    GroupsView()
        .environmentObject(AuthManager.shared)
}
