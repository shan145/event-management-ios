import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var upcomingEvents: [Event] = []
    @Published var myGroups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
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
            async let eventsTask = loadUpcomingEvents()
            async let groupsTask = loadMyGroups()
            
            let (events, groups) = await (try eventsTask, try groupsTask)
            
            print("✅ Dashboard loaded: \(events.count) events, \(groups.count) groups")
            upcomingEvents = events
            myGroups = groups
            
        } catch {
            print("❌ Dashboard error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
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
    
    private func loadMyGroups() async throws -> [Group] {
        print("🔍 Loading my groups...")
        let response = try await apiService.getUserGroups()
        print("✅ My groups loaded: \(response.data.groups.count) groups")
        return response.data.groups
    }
    
    func refreshData() async {
        await loadDashboardData()
    }
}
