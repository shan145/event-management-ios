import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = AdminDashboardViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Text("Admin Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Admin Header
                    adminHeader
                    
                    if !viewModel.isLoading {
                        // System Stats
                        systemStatsSection
                        
                        // Recent Users
                        recentUsersSection
                        
                        // Recent Events
                        recentEventsSection
                        
                        // Admin Actions
                        adminActionsSection
                    } else {
                        LoadingView()
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
            .background(Color.appBackground)
            .refreshable {
                await viewModel.loadAdminData()
            }
        }
        .task {
            await viewModel.loadAdminData()
        }
    }
    
    private var adminHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Admin Dashboard")
                        .font(AppTypography.h3)
                        .foregroundColor(Color.appTextPrimary)
                    
                    Text("System overview and management")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "shield.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.appPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var systemStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.md) {
            AdminStatCard(
                title: "Total Users",
                value: "\(viewModel.totalUsers)",
                icon: "person.2",
                color: Color.appPrimary
            )
            
            AdminStatCard(
                title: "Total Groups",
                value: "\(viewModel.totalGroups)",
                icon: "person.3",
                color: Color.appSecondary
            )
            
            AdminStatCard(
                title: "Total Events",
                value: "\(viewModel.totalEvents)",
                icon: "calendar",
                color: Color.grey600
            )
        }
    }
    
    private var recentUsersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Users")
                    .font(AppTypography.h4)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to user management
                }
                .buttonStyle(TextButtonStyle())
            }
            
            if viewModel.recentUsers.isEmpty {
                emptyStateView(
                    icon: "person.2",
                    title: "No users yet",
                    message: "Users will appear here once they sign up"
                )
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.recentUsers.prefix(5)) { user in
                        UserRowView(user: user)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var recentEventsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Events")
                    .font(AppTypography.h4)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to events list
                }
                .buttonStyle(TextButtonStyle())
            }
            
            if viewModel.recentEvents.isEmpty {
                emptyStateView(
                    icon: "calendar",
                    title: "No events yet",
                    message: "Events will appear here once they're created"
                )
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.recentEvents.prefix(5)) { event in
                        AdminEventRowView(event: event)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var adminActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Admin Actions")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                AdminActionCard(
                    title: "Manage Users",
                    icon: "person.2",
                    color: Color.appPrimary
                ) {
                    // TODO: Navigate to user management
                }
                
                AdminActionCard(
                    title: "Manage Groups",
                    icon: "person.3",
                    color: Color.appSecondary
                ) {
                    // TODO: Navigate to group management
                }
                
                AdminActionCard(
                    title: "System Settings",
                    icon: "gear",
                    color: Color.grey600
                ) {
                    // TODO: Navigate to system settings
                }
                
                AdminActionCard(
                    title: "View Logs",
                    icon: "doc.text",
                    color: Color.grey600
                ) {
                    // TODO: Navigate to system logs
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

struct AdminStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(AppTypography.h3)
                .foregroundColor(Color.appTextPrimary)
            
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
}

struct AdminActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 28))
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

struct UserRowView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(user.fullName)
                    .font(AppTypography.body1)
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                
                Text(user.email)
                    .font(AppTypography.caption)
                    .foregroundColor(Color.appTextSecondary)
            }
            
            Spacer()
            
            HStack(spacing: AppSpacing.xs) {
                if user.isAdmin {
                    Text("Admin")
                        .font(AppTypography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color.appPrimary)
                        .cornerRadius(AppCornerRadius.small)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextSecondary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.grey50)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct AdminEventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(event.title)
                    .font(AppTypography.body1)
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                
                Text("\(event.formattedDate) • \(event.formattedTime)")
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
    AdminDashboardView()
        .environmentObject(AuthManager.shared)
}
