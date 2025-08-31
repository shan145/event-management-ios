import Foundation

@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var filteredEvents: [Event] = []
    @Published var selectedFilter: EventFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    enum EventFilter {
        case all
        case upcoming
        case past
        case myEvents
    }
    
    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔍 Loading events...")
            let response = try await apiService.getEvents()
            print("✅ Events response: \(response)")
            print("📊 Events count: \(response.data.events.count)")
            events = response.data.events
            filterEvents()
        } catch {
            print("❌ Error loading events: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func filterEvents(searchText: String = "") {
        var filtered = events
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            filtered = filterUpcomingEvents(events)
        case .past:
            filtered = filterPastEvents(events)
        case .myEvents:
            filtered = filterMyEvents(events)
        }
        
        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                (event.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (event.location?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Sort by date
        filtered.sort { event1, event2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            guard let date1 = formatter.date(from: event1.date),
                  let date2 = formatter.date(from: event2.date) else { return false }
            
            return date1 < date2
        }
        
        filteredEvents = filtered
    }
    
    private func filterUpcomingEvents(_ events: [Event]) -> [Event] {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return events.filter { event in
            guard let eventDate = formatter.date(from: event.date) else { return false }
            return eventDate >= today
        }
    }
    
    private func filterPastEvents(_ events: [Event]) -> [Event] {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return events.filter { event in
            guard let eventDate = formatter.date(from: event.date) else { return false }
            return eventDate < today
        }
    }
    
    private func filterMyEvents(_ events: [Event]) -> [Event] {
        // TODO: Implement when we have user ID in events
        // For now, return all events
        return events
    }
    
    func refreshEvents() async {
        await loadEvents()
    }
}
