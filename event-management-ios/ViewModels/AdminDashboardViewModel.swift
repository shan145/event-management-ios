import Foundation

@MainActor
class AdminDashboardViewModel: ObservableObject {
    @Published var recentUsers: [User] = []
    @Published var recentEvents: [Event] = []
    @Published var allGroups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    var totalUsers: Int {
        let count = recentUsers.count
        print("📊 Admin totalUsers: \(count)")
        return count
    }
    
    var totalGroups: Int {
        let count = allGroups.count
        print("📊 Admin totalGroups: \(count)")
        return count
    }
    
    var totalEvents: Int {
        let count = recentEvents.count
        return count
    }
    
    func loadAdminData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔍 Loading admin data...")
            async let usersTask = loadRecentUsers()
            async let eventsTask = loadRecentEvents()
            async let groupsTask = loadAllGroups()
            
            let (users, events, groups) = await (try usersTask, try eventsTask, try groupsTask)
            
            print("✅ Admin data loaded: \(users.count) users, \(events.count) events, \(groups.count) groups")
            recentUsers = users
            recentEvents = events
            allGroups = groups
            
        } catch {
            print("❌ Admin data error: \(error)")
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
    
    private func loadAllGroups() async throws -> [Group] {
        print("🔍 Loading all groups...")
        let response = try await apiService.getGroups()
        let groups = response.data.groups
        print("✅ All groups loaded: \(groups.count) groups")
        
        // Sort by creation date (most recent first)
        return groups.sorted { group1, group2 in
            guard let date1 = group1.createdAt,
                  let date2 = group2.createdAt else { return false }
            return date1 > date2
        }
    }
    
    func refreshData() async {
        await loadAdminData()
    }
}
