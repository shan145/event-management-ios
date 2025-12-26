import Foundation

// MARK: - TimeFilter enum
enum TimeFilter: String, CaseIterable {
    case upcoming = "upcoming"
    case past = "past"
    
    var displayName: String {
        switch self {
        case .upcoming:
            return "Upcoming"
        case .past:
            return "Past"
        }
    }
}

// MARK: - UserDefaults extension for storing filter preferences
extension UserDefaults {
    private enum Keys {
        static let selectedGroupFilter = "selectedGroupFilter"
        static let selectedTimeFilter = "selectedTimeFilter"
    }
    
    var selectedGroupFilter: String? {
        get { string(forKey: Keys.selectedGroupFilter) }
        set { set(newValue, forKey: Keys.selectedGroupFilter) }
    }
    
    var selectedTimeFilter: String? {
        get { string(forKey: Keys.selectedTimeFilter) }
        set { set(newValue, forKey: Keys.selectedTimeFilter) }
    }
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var upcomingEvents: [Event] = []
    @Published var pastEvents: [Event] = []
    @Published var myGroups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCounts: [String: Int] = [:]
    
    // Filter state
    @Published var selectedGroupFilter: String = "all" // "all" or group ID
    @Published var selectedTimeFilter: TimeFilter = .upcoming // "upcoming" or "past"
    @Published var filteredEvents: [Event] = []
    
    private let apiService = APIService.shared
    
    init() {
        // Load saved filter preferences
        selectedGroupFilter = UserDefaults.standard.selectedGroupFilter ?? "all"
        if let savedTimeFilter = UserDefaults.standard.selectedTimeFilter,
           let timeFilter = TimeFilter(rawValue: savedTimeFilter) {
            selectedTimeFilter = timeFilter
        }
    }
    
    var upcomingEventsCount: Int {
        let count = upcomingEvents.count
        print("📊 Dashboard upcomingEventsCount: \(count)")
        return count
    }
    
    var myGroupsCount: Int {
        let count = myGroups.count
        print("📊 Dashboard myGroupsCount: \(count)")
        return count
    }
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔍 Loading dashboard data...")
            async let upcomingEventsTask = loadUpcomingEvents()
            async let pastEventsTask = loadPastEvents()
            async let groupsTask = loadMyGroups()
            
            let (upcomingEvents, pastEvents, groups) = await (try upcomingEventsTask, try pastEventsTask, try groupsTask)
            
            print("✅ Dashboard loaded: \(upcomingEvents.count) upcoming events, \(pastEvents.count) past events, \(groups.count) groups")
            self.upcomingEvents = upcomingEvents
            self.pastEvents = pastEvents
            self.myGroups = groups
            updateFilteredEvents() // Apply current filter
            
            // Load unread message counts
            await loadUnreadCounts()
            
        } catch {
            print("❌ Dashboard error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadUnreadCounts() async {
        let allEventIds = (upcomingEvents + pastEvents).map { $0.id }
        
        guard !allEventIds.isEmpty else {
            return
        }
        
        do {
            let response = try await apiService.getUnreadCounts(eventIds: allEventIds)
            self.unreadCounts = response.data.unreadCounts
        } catch {
            print("⚠️ Failed to load unread counts: \(error)")
            // Don't fail the whole load if unread counts fail
        }
    }
    
    func getUnreadCount(for eventId: String) -> Int {
        return unreadCounts[eventId] ?? 0
    }
    
    private func loadUpcomingEvents() async throws -> [Event] {
        print("🔍 Loading user events...")
        let response = try await apiService.getUserEvents()
        let events = response.data.events
        print("✅ User events loaded: \(events.count) events")
        
        // No filtering - show all user events
        print("🔍 Total events loaded from API: \(events.count)")
        events.forEach { event in
            print("🔍 Event: '\(event.title)' - Date: '\(event.date)' - GroupId: \(event.groupId)")
        }
        
        // Return all events without any filtering, sorted by date (newest first)
        let upcomingEvents = events.sorted { event1, event2 in
            // Sort by date if possible, otherwise by title
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            if let date1 = formatter.date(from: event1.date),
               let date2 = formatter.date(from: event2.date) {
                return date1 > date2  // Newest first
            } else {
                return event1.title < event2.title  // Fallback to alphabetical
            }
        }
        
        print("✅ All user events: \(upcomingEvents.count) events")
        return upcomingEvents
    }
    
    private func loadPastEvents() async throws -> [Event] {
        print("🔍 Loading past events...")
        let response = try await apiService.getPastEvents()
        let events = response.data.events
        print("✅ Past events loaded: \(events.count) events")
        
        // Sort past events by date (most recent first)
        let pastEvents = events.sorted { event1, event2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            if let date1 = formatter.date(from: event1.date),
               let date2 = formatter.date(from: event2.date) {
                return date1 > date2  // Most recent first
            } else {
                return event1.title < event2.title  // Fallback to alphabetical
            }
        }
        
        print("✅ All past events: \(pastEvents.count) events")
        return pastEvents
    }
    
    private func loadMyGroups() async throws -> [Group] {
        print("🔍 Loading my groups...")
        let response = try await apiService.getUserGroups()
        print("✅ My groups loaded: \(response.data.groups.count) groups")
        return response.data.groups
    }
    
    func refreshData() async {
        await loadDashboardData()
    }
    
    // MARK: - Filtering Methods
    
    func setGroupFilter(_ groupId: String) {
        selectedGroupFilter = groupId
        UserDefaults.standard.selectedGroupFilter = groupId
        updateFilteredEvents()
    }
    
    func setTimeFilter(_ timeFilter: TimeFilter) {
        selectedTimeFilter = timeFilter
        UserDefaults.standard.selectedTimeFilter = timeFilter.rawValue
        updateFilteredEvents()
    }
    
    private func updateFilteredEvents() {
        // Get the appropriate events based on time filter
        let sourceEvents = selectedTimeFilter == .upcoming ? upcomingEvents : pastEvents
        
        // Apply group filter
        if selectedGroupFilter == "all" {
            filteredEvents = sourceEvents
        } else {
            filteredEvents = sourceEvents.filter { event in
                switch event.groupId {
                case .group(let group):
                    return group.id == selectedGroupFilter
                case .populatedGroup(let popGroup):
                    return popGroup.id == selectedGroupFilter
                case .id(let id):
                    return id == selectedGroupFilter
                }
            }
        }
        
        print("🔍 Filter applied: '\(selectedTimeFilter.rawValue)' + '\(selectedGroupFilter)' -> \(filteredEvents.count) events")
    }
    
    var availableGroupFilters: [GroupFilter] {
        let sourceEvents = selectedTimeFilter == .upcoming ? upcomingEvents : pastEvents
        
        var filters: [GroupFilter] = [
            GroupFilter(id: "all", name: "All Groups", eventCount: sourceEvents.count)
        ]
        
        for group in myGroups {
            let eventCount = sourceEvents.filter { event in
                switch event.groupId {
                case .group(let g):
                    return g.id == group.id
                case .populatedGroup(let pg):
                    return pg.id == group.id
                case .id(let id):
                    return id == group.id
                }
            }.count
            
            if eventCount > 0 { // Only show groups that have events
                filters.append(GroupFilter(id: group.id, name: group.name, eventCount: eventCount))
            }
        }
        
        return filters
    }
}

// MARK: - Supporting Models

struct GroupFilter: Identifiable, Equatable {
    let id: String
    let name: String
    let eventCount: Int
}
