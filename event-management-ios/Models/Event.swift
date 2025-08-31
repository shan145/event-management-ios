import Foundation

struct Event: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let location: String?
    let date: String
    let time: String
    let maxAttendees: Int?
    let guests: Int
    let groupId: String
    let createdBy: String
    let createdAt: String?
    let updatedAt: String?
    let attendees: [User]?
    let waitlist: [User]?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: date) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return date
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let time = formatter.date(from: time) {
            formatter.timeStyle = .short
            return formatter.string(from: time)
        }
        return time
    }
    
    var isUnlimited: Bool {
        maxAttendees == nil
    }
    
    // Computed properties for the new views
    var isOrganizer: Bool {
        // TODO: Compare with current user ID
        return false
    }
    
    var isAttending: Bool {
        // TODO: Check if current user is in attendees list
        return false
    }
    
    static let sampleEvent = Event(
        id: "sample-event-id",
        title: "Sample Event",
        description: "This is a sample event description",
        location: "Sample Location",
        date: "2024-01-15",
        time: "14:00",
        maxAttendees: 50,
        guests: 0,
        groupId: "sample-group-id",
        createdBy: "sample-user-id",
        createdAt: "2024-01-01T00:00:00Z",
        updatedAt: "2024-01-01T00:00:00Z",
        attendees: [],
        waitlist: []
    )
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case description
        case location
        case date
        case time
        case maxAttendees
        case guests
        case groupId
        case createdBy
        case createdAt
        case updatedAt
        case attendees
        case waitlist
    }
}

struct EventResponse: Codable {
    let success: Bool
    let message: String?
    let data: EventData
}

struct EventData: Codable {
    let event: Event
}

struct EventsResponse: Codable {
    let success: Bool
    let message: String?
    let data: EventsData
}

struct EventsData: Codable {
    let events: [Event]
}

struct EventAttendeesResponse: Codable {
    let success: Bool
    let message: String?
    let data: EventAttendeesData
}

struct EventAttendeesData: Codable {
    let attendees: [User]
    let totalCount: Int
    let eventTitle: String
}
