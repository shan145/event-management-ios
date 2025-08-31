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
        print("🔍 Loading upcoming events...")
        let response = try await apiService.getEvents()
        let events = response.data.events
        print("✅ All events loaded: \(events.count) events")
        
        // Filter for upcoming events (today and future)
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let upcomingEvents = events.filter { event in
            guard let eventDate = formatter.date(from: event.date) else { return false }
            return eventDate >= today
        }.sorted { event1, event2 in
            guard let date1 = formatter.date(from: event1.date),
                  let date2 = formatter.date(from: event2.date) else { return false }
            return date1 < date2
        }
        
        print("✅ Upcoming events filtered: \(upcomingEvents.count) events")
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
