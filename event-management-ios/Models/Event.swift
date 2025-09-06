import Foundation

// Simple structure for populated groupId from events
struct PopulatedGroup: Codable, Equatable {
    let id: String
    let name: String
    let members: [String]?  // Array of user IDs as strings per API docs
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case members
    }
}

// Location structure for events
struct EventLocation: Codable, Equatable {
    let name: String
    let url: String?
}

// Enum to handle event group as either Group object, PopulatedGroup, or string ID
enum EventGroup: Codable, Equatable {
    case group(Group)
    case populatedGroup(PopulatedGroup)
    case id(String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        print("🔍 EventGroup decoder - attempting to decode groupId")
        
        // Try to decode as PopulatedGroup first (most common case)
        do {
            let populatedGroup = try container.decode(PopulatedGroup.self)
            print("✅ EventGroup decoded as PopulatedGroup: \(populatedGroup.name)")
            self = .populatedGroup(populatedGroup)
            return
        } catch {
            print("🔍 PopulatedGroup decode failed: \(error)")
        }
        
        // Try Group next
        do {
            let group = try container.decode(Group.self)
            print("✅ EventGroup decoded as Group: \(group.name)")
            self = .group(group)
            return
        } catch {
            print("🔍 Group decode failed: \(error)")
        }
        
        // Try String ID last
        do {
            let id = try container.decode(String.self)
            print("✅ EventGroup decoded as String ID: \(id)")
            self = .id(id)
            return
        } catch {
            print("🔍 String decode failed: \(error)")
        }
        
        print("❌ EventGroup decoder failed - could not decode as any expected type")
        throw DecodingError.typeMismatch(EventGroup.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected PopulatedGroup, Group object, or String ID"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .group(let group):
            try container.encode(group)
        case .populatedGroup(let populatedGroup):
            try container.encode(populatedGroup)
        case .id(let id):
            try container.encode(id)
        }
    }
    
    var group: Group? {
        switch self {
        case .group(let group):
            return group
        case .populatedGroup, .id:
            return nil
        }
    }
    
    var populatedGroup: PopulatedGroup? {
        switch self {
        case .populatedGroup(let populatedGroup):
            return populatedGroup
        case .group, .id:
            return nil
        }
    }
    
    var id: String? {
        switch self {
        case .group(let group):
            return group.id
        case .populatedGroup(let populatedGroup):
            return populatedGroup.id
        case .id(let id):
            return id
        }
    }
    
    var name: String? {
        switch self {
        case .group(let group):
            return group.name
        case .populatedGroup(let populatedGroup):
            return populatedGroup.name
        case .id:
            return nil
        }
    }
}

// Enum to handle event creator as either User object or string ID
enum EventCreator: Codable, Equatable {
    case user(User)
    case id(String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let user = try? container.decode(User.self) {
            self = .user(user)
        } else if let id = try? container.decode(String.self) {
            self = .id(id)
        } else {
            throw DecodingError.typeMismatch(EventCreator.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected User object or String ID"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .user(let user):
            try container.encode(user)
        case .id(let id):
            try container.encode(id)
        }
    }
    
    var user: User? {
        switch self {
        case .user(let user):
            return user
        case .id:
            return nil
        }
    }
    
    var id: String? {
        switch self {
        case .user(let user):
            return user.id
        case .id(let id):
            return id
        }
    }
}

struct Event: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let location: EventLocation?
    let date: String
    let time: String
    let maxAttendees: Int?
    let guests: Int
    let groupId: EventGroup
    let createdBy: EventCreator
    let createdAt: String?
    let updatedAt: String?
    let goingList: [User]?
    let waitlist: [User]?
    let noGoList: [User]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Handle location as either EventLocation object or String (for backward compatibility)
        if let locationObject = try? container.decode(EventLocation.self, forKey: .location) {
            location = locationObject
        } else if let locationString = try? container.decode(String.self, forKey: .location) {
            // Convert string to EventLocation for backward compatibility
            location = EventLocation(name: locationString, url: nil)
        } else {
            location = nil
        }
        
        date = try container.decode(String.self, forKey: .date)
        time = try container.decode(String.self, forKey: .time)
        maxAttendees = try container.decodeIfPresent(Int.self, forKey: .maxAttendees)
        guests = try container.decode(Int.self, forKey: .guests)
        goingList = try container.decodeIfPresent([User].self, forKey: .goingList)
        waitlist = try container.decodeIfPresent([User].self, forKey: .waitlist)
        noGoList = try container.decodeIfPresent([User].self, forKey: .noGoList)
        
        // Handle createdBy as either String or User object
        if let createdByString = try? container.decode(String.self, forKey: .createdBy) {
            createdBy = EventCreator.id(createdByString)
        } else if let createdByUser = try? container.decode(User.self, forKey: .createdBy) {
            createdBy = EventCreator.user(createdByUser)
        } else {
            throw DecodingError.typeMismatch(EventCreator.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String ID or User object for createdBy"))
        }
        
        // Handle createdAt as either String or Date
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = createdAtString
        } else if let createdAtDate = try? container.decode(Date.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.string(from: createdAtDate)
        } else {
            createdAt = nil
        }
        
        // Handle updatedAt as either String or Date
        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = updatedAtString
        } else if let updatedAtDate = try? container.decode(Date.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            updatedAt = formatter.string(from: updatedAtDate)
        } else {
            updatedAt = nil
        }
        
        // Handle groupId as either String, PopulatedGroup, or Group object
        if let groupIdString = try? container.decode(String.self, forKey: .groupId) {
            groupId = EventGroup.id(groupIdString)
        } else if let populatedGroup = try? container.decode(PopulatedGroup.self, forKey: .groupId) {
            groupId = EventGroup.populatedGroup(populatedGroup)
        } else if let groupObject = try? container.decode(Group.self, forKey: .groupId) {
            groupId = EventGroup.group(groupObject)
        } else {
            // If all else fails, try to extract just the ID as a fallback
            print("⚠️ Warning: Could not decode groupId properly, using fallback")
            groupId = EventGroup.id("unknown-group-id")
        }
    }
    
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
    
    var formattedDateTime: String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy h:mm a"
        outputFormatter.locale = Locale(identifier: "en_US")
        outputFormatter.timeZone = TimeZone(identifier: "America/New_York")
        
        // First, try to parse the date field as an ISO timestamp (which seems to be the case)
        let isoFormatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        ]
        
        // Try parsing the date field as ISO timestamp
        for format in isoFormatters {
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = format
            inputFormatter.timeZone = TimeZone(identifier: "UTC")
            
            if let parsedDate = inputFormatter.date(from: date) {
                return outputFormatter.string(from: parsedDate) + " ET"
            }
        }
        
        // If the date field is not ISO, try combining date and time
        let dateTime = "\(date) \(time)"
        let combinedFormatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in combinedFormatters {
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = format
            inputFormatter.timeZone = TimeZone(identifier: "UTC")
            
            if let parsedDate = inputFormatter.date(from: dateTime) {
                return outputFormatter.string(from: parsedDate) + " ET"
            }
        }
        
        // Try parsing date and time separately as a fallback
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        if let parsedDate = dateFormatter.date(from: date),
           let parsedTime = timeFormatter.date(from: time) {
            
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: parsedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: parsedTime)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            
            if calendar.date(from: combinedComponents) != nil {
                // Assume the original time is in UTC and convert to ET
                var utcCalendar = Calendar.current
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                if let utcDate = utcCalendar.date(from: combinedComponents) {
                    return outputFormatter.string(from: utcDate) + " ET"
                }
            }
        }
        
        // Final fallback
        return "\(formattedDate) \(formattedTime) ET"
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
        location: EventLocation(name: "Sample Location", url: nil),
        date: "2024-01-15",
        time: "14:00",
        maxAttendees: 50,
        guests: 0,
        groupId: EventGroup.id("sample-group-id"),
        createdBy: EventCreator.id("sample-user-id"),
        createdAt: "2024-01-01T00:00:00Z",
        updatedAt: "2024-01-01T00:00:00Z",
        goingList: [],
        waitlist: [],
        noGoList: []
    )
    
    // Custom initializer for creating Event instances
    init(id: String, title: String, description: String?, location: EventLocation?, date: String, time: String, maxAttendees: Int?, guests: Int, groupId: EventGroup, createdBy: EventCreator, createdAt: String?, updatedAt: String?, goingList: [User]?, waitlist: [User]?, noGoList: [User]?) {
        self.id = id
        self.title = title
        self.description = description
        self.location = location
        self.date = date
        self.time = time
        self.maxAttendees = maxAttendees
        self.guests = guests
        self.groupId = groupId
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.goingList = goingList
        self.waitlist = waitlist
        self.noGoList = noGoList
    }
    
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
        case goingList
        case waitlist
        case noGoList
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


