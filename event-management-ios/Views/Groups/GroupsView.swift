import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = GroupsViewModel()
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showCreateGroup = true }) {
                            Label("Create Group", systemImage: "plus.circle")
                        }
                        
                        Button(action: { showJoinGroup = true }) {
                            Label("Join Group", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadGroups()
            }
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
                NavigationLink(destination: GroupDetailView(group: group)) {
                    GroupCardView(group: group) {
                        // Navigation is handled by NavigationLink
                    }
                }
                .buttonStyle(PlainButtonStyle())
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
                AppButton(title: "Create Group", action: {
                    showCreateGroup = true
                })
                .frame(maxWidth: 150)
                
                AppButton(title: "Join Group", action: {
                    showJoinGroup = true
                }, style: .secondary)
                .frame(maxWidth: 150)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - Supporting Views

struct GroupCardView: View {
    let group: Group
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(group.name)
                            .font(AppTypography.h5)
                            .foregroundColor(Color.appTextPrimary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Member count badge
                    memberCountBadge
                }
                
                // Group stats
                HStack(spacing: AppSpacing.lg) {
                    GroupStatItem(
                        icon: "person.2",
                        text: "\(group.memberCount) members"
                    )
                    
                    GroupStatItem(
                        icon: "calendar",
                        text: "\(group.eventCount) events"
                    )
                }
            }
            .padding(AppSpacing.lg)
            .background(Color.appSurface)
            .cornerRadius(AppCornerRadius.large)
            .appShadow(AppShadows.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var memberCountBadge: some View {
        Text("\(group.memberCount)")
            .font(AppTypography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(Color.appPrimary)
            .cornerRadius(AppCornerRadius.small)
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
