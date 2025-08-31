import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var upcomingEvents: [Event] = []
    @Published var myGroups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    var upcomingEventsCount: Int {
        upcomingEvents.count
    }
    
    var myGroupsCount: Int {
        myGroups.count
    }
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let eventsTask = loadUpcomingEvents()
            async let groupsTask = loadMyGroups()
            
            let (events, groups) = await (try eventsTask, try groupsTask)
            
            upcomingEvents = events
            myGroups = groups
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadUpcomingEvents() async throws -> [Event] {
        let response = try await apiService.getEvents()
        let events = response.data.events
        
        // Filter for upcoming events (today and future)
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return events.filter { event in
            guard let eventDate = formatter.date(from: event.date) else { return false }
            return eventDate >= today
        }.sorted { event1, event2 in
            guard let date1 = formatter.date(from: event1.date),
                  let date2 = formatter.date(from: event2.date) else { return false }
            return date1 < date2
        }
    }
    
    private func loadMyGroups() async throws -> [Group] {
        let response = try await apiService.getGroups()
        return response.data.groups
    }
    
    func refreshData() async {
        await loadDashboardData()
    }
}
