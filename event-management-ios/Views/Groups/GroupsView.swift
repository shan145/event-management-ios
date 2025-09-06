import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var viewModel: DashboardViewModel
    
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
                    
                    Text("\(viewModel.myGroups.count) group\(viewModel.myGroups.count == 1 ? "" : "s")")
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
                    LazyVStack(spacing: AppSpacing.lg) {
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
        .background(Color.appBackground)
        .task {
            await viewModel.loadDashboardData()
        }
        .refreshable {
            await viewModel.loadDashboardData()
        }
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(Color.grey400)
            
            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                
                Text(message)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Color.grey600)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xxl)
    }
}

#Preview {
    GroupsView()
        .environmentObject(AuthManager.shared)
}
