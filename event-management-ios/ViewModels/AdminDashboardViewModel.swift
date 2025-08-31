import Foundation

@MainActor
class AdminDashboardViewModel: ObservableObject {
    @Published var recentUsers: [User] = []
    @Published var recentEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    var totalUsers: Int {
        recentUsers.count
    }
    
    var totalGroups: Int {
        // TODO: Implement when we have groups data
        return 0
    }
    
    var totalEvents: Int {
        recentEvents.count
    }
    
    func loadAdminData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let usersTask = loadRecentUsers()
            async let eventsTask = loadRecentEvents()
            
            let (users, events) = await (try usersTask, try eventsTask)
            
            recentUsers = users
            recentEvents = events
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadRecentUsers() async throws -> [User] {
        let response = try await apiService.getUsers()
        let users = response.data.users
        
        // Sort by creation date (most recent first)
        return users.sorted { user1, user2 in
            guard let date1 = user1.createdAt,
                  let date2 = user2.createdAt else { return false }
            return date1 > date2
        }
    }
    
    private func loadRecentEvents() async throws -> [Event] {
        let response = try await apiService.getEvents()
        let events = response.data.events
        
        // Sort by creation date (most recent first)
        return events.sorted { event1, event2 in
            guard let date1 = event1.createdAt,
                  let date2 = event2.createdAt else { return false }
            return date1 > date2
        }
    }
    
    func refreshData() async {
        await loadAdminData()
    }
}
