import Foundation

@MainActor
class GroupsViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var filteredGroups: [Group] = []
    @Published var selectedFilter: GroupFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    enum GroupFilter {
        case all
        case myGroups
        case available
    }
    
    func loadGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getGroups()
            groups = response.data.groups
            filterGroups()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func filterGroups(searchText: String = "") {
        var filtered = groups
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .myGroups:
            filtered = filterMyGroups(groups)
        case .available:
            filtered = filterAvailableGroups(groups)
        }
        
        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by name
        filtered.sort { $0.name < $1.name }
        
        filteredGroups = filtered
    }
    
    private func filterMyGroups(_ groups: [Group]) -> [Group] {
        // TODO: Implement when we have user membership data
        // For now, return all groups
        return groups
    }
    
    private func filterAvailableGroups(_ groups: [Group]) -> [Group] {
        // TODO: Implement when we have user membership data
        // For now, return all groups
        return groups
    }
    
    func refreshGroups() async {
        await loadGroups()
    }
}
