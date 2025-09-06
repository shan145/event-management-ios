import SwiftUI

struct EventsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var viewModel: DashboardViewModel
    
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
        .background(Color.appBackground)
        .task {
            await viewModel.loadDashboardData()
        }
        .refreshable {
            await viewModel.loadDashboardData()
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

#Preview {
    EventsView()
        .environmentObject(AuthManager.shared)
        .environmentObject(DashboardViewModel())
}
