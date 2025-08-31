import SwiftUI

struct EventsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = EventsViewModel()
    @State private var showCreateEvent = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCreateEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadEvents()
            }
        }
        .task {
            await viewModel.loadEvents()
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
                NavigationLink(destination: EventDetailView(event: event)) {
                    EventCardView(event: event) {
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
            
            AppButton(title: "Create Event", action: {
                showCreateEvent = true
            })
            .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
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
    let event: Event
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
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
                    
                    // Status indicator
                    statusIndicator
                }
                
                // Event details
                HStack(spacing: AppSpacing.lg) {
                    EventDetailItem(
                        icon: "calendar",
                        text: event.formattedDate
                    )
                    
                    EventDetailItem(
                        icon: "clock",
                        text: event.formattedTime
                    )
                    
                    if let location = event.location {
                        EventDetailItem(
                            icon: "location",
                            text: location
                        )
                    }
                }
                
                // Capacity info
                if let maxAttendees = event.maxAttendees {
                    HStack {
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextSecondary)
                        
                        Text("Capacity: \(maxAttendees) people")
                            .font(AppTypography.caption)
                            .foregroundColor(Color.appTextSecondary)
                        
                        Spacer()
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
    
    private var statusIndicator: some View {
        let (color, text) = eventStatus
        return Text(text)
            .font(AppTypography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(color)
            .cornerRadius(AppCornerRadius.small)
    }
    
    private var eventStatus: (Color, String) {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let eventDate = formatter.date(from: event.date) else {
            return (Color.grey600, "Unknown")
        }
        
        if eventDate < today {
            return (Color.grey600, "Past")
        } else if Calendar.current.isDate(eventDate, inSameDayAs: today) {
            return (Color.appPrimary, "Today")
        } else {
            return (Color.appSecondary, "Upcoming")
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

#Preview {
    EventsView()
        .environmentObject(AuthManager.shared)
}
