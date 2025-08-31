import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Quick Stats
                    if !viewModel.isLoading {
                        statsSection
                        
                        // Upcoming Events
                        upcomingEventsSection
                        
                        // My Groups
                        myGroupsSection
                        
                        // Quick Actions
                        quickActionsSection
                    } else {
                        LoadingView()
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
            .background(Color.appBackground)
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboardData()
            }
        }
        .task {
            await viewModel.loadDashboardData()
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Welcome back, \(authManager.currentUser?.firstName ?? "User")!")
                .font(AppTypography.h3)
                .foregroundColor(Color.appTextPrimary)
            
            Text("Here's what's happening with your events")
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.md) {
            StatCard(
                icon: "calendar",
                title: "Upcoming Events",
                value: "\(viewModel.upcomingEventsCount)",
                color: Color.appPrimary
            )
            
            StatCard(
                icon: "person.3",
                title: "My Groups",
                value: "\(viewModel.myGroupsCount)",
                color: Color.appSecondary
            )
        }
    }
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Upcoming Events")
                    .font(AppTypography.h4)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to events list
                }
                .buttonStyle(TextButtonStyle())
            }
            
            if viewModel.upcomingEvents.isEmpty {
                emptyStateView(
                    icon: "calendar",
                    title: "No upcoming events",
                    message: "You don't have any events scheduled"
                )
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.upcomingEvents.prefix(3)) { event in
                        EventRowView(event: event)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var myGroupsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("My Groups")
                    .font(AppTypography.h4)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to groups list
                }
                .buttonStyle(TextButtonStyle())
            }
            
            if viewModel.myGroups.isEmpty {
                emptyStateView(
                    icon: "person.3",
                    title: "No groups yet",
                    message: "Join a group to start managing events"
                )
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.myGroups.prefix(3)) { group in
                        GroupRowView(group: group)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quick Actions")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                QuickActionCard(
                    title: "Create Event",
                    icon: "plus.circle",
                    color: Color.appPrimary
                ) {
                    // TODO: Navigate to create event
                }
                
                QuickActionCard(
                    title: "Join Group",
                    icon: "person.badge.plus",
                    color: Color.appSecondary
                ) {
                    // TODO: Navigate to join group
                }
                
                if authManager.currentUser?.isAdmin == true {
                    QuickActionCard(
                        title: "Manage Users",
                        icon: "person.2",
                        color: Color.grey600
                    ) {
                        // TODO: Navigate to user management
                    }
                }
                
                QuickActionCard(
                    title: "Settings",
                    icon: "gear",
                    color: Color.grey600
                ) {
                    // TODO: Navigate to settings
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
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

// MARK: - Supporting Views

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTypography.body2)
                    .foregroundColor(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.lg)
            .background(Color.appSurface)
            .cornerRadius(AppCornerRadius.large)
            .appShadow(AppShadows.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(event.title)
                    .font(AppTypography.body1)
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                
                Text("\(event.formattedDate) at \(event.formattedTime)")
                    .font(AppTypography.caption)
                    .foregroundColor(Color.appTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.appTextSecondary)
        }
        .padding(AppSpacing.md)
        .background(Color.grey50)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct GroupRowView: View {
    let group: Group
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(group.name)
                    .font(AppTypography.body1)
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                
                Text("\(group.memberCount) members • \(group.eventCount) events")
                    .font(AppTypography.caption)
                    .foregroundColor(Color.appTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.appTextSecondary)
        }
        .padding(AppSpacing.md)
        .background(Color.grey50)
        .cornerRadius(AppCornerRadius.medium)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}
