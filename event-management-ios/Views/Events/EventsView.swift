import SwiftUI

struct EventsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var viewModel: DashboardViewModel
    
    private var selectedFilterName: String {
        if viewModel.selectedGroupFilter == "all" {
            return "No upcoming events"
        } else {
            let groupName = viewModel.availableGroupFilters.first { $0.id == viewModel.selectedGroupFilter }?.name ?? "Unknown Group"
            return "No events in \(groupName)"
        }
    }
    
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
                    
                    Text("\(viewModel.filteredEvents.count) event\(viewModel.filteredEvents.count == 1 ? "" : "s")")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                
                // Group Filters
                if !viewModel.availableGroupFilters.isEmpty {
                    GroupFilterScrollView(
                        filters: viewModel.availableGroupFilters,
                        selectedFilter: viewModel.selectedGroupFilter,
                        onFilterSelected: { groupId in
                            viewModel.setGroupFilter(groupId)
                        }
                    )
                }
                
                // Events List
                if viewModel.isLoading {
                    LoadingView()
                        .frame(height: 200)
                } else if viewModel.filteredEvents.isEmpty {
                    emptyStateView(
                        icon: "calendar",
                        title: selectedFilterName,
                        message: viewModel.upcomingEvents.isEmpty ? 
                                "You don't have any events scheduled" : 
                                "No events found for this group"
                    )
                } else {
                    LazyVStack(spacing: AppSpacing.lg) {
                        ForEach(viewModel.filteredEvents) { event in
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

// MARK: - Group Filter Component

struct GroupFilterScrollView: View {
    let filters: [GroupFilter]
    let selectedFilter: String
    let onFilterSelected: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.md) {
                ForEach(filters) { filter in
                    GroupFilterButton(
                        filter: filter,
                        isSelected: filter.id == selectedFilter,
                        onTap: {
                            onFilterSelected(filter.id)
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}

struct GroupFilterButton: View {
    let filter: GroupFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.xs) {
                Text(filter.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? Color.white : Color.appTextPrimary)
                
                if filter.eventCount > 0 {
                    Text("\(filter.eventCount)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? Color.white.opacity(0.8) : Color.appTextSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.white.opacity(0.2) : Color.grey200)
                        )
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary : Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color.grey200, lineWidth: 1)
                    )
            )
            .appShadow(isSelected ? AppShadows.small : AppShadows.none)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    EventsView()
        .environmentObject(AuthManager.shared)
        .environmentObject(DashboardViewModel())
}
