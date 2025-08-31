import Foundation

struct Group: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let members: [User]?
    let admins: [User]?
    let events: [Event]?
    let createdAt: String?
    let updatedAt: String?
    
    var memberCount: Int {
        members?.count ?? 0
    }
    
    var eventCount: Int {
        events?.count ?? 0
    }
    
    var formattedCreatedDate: String {
        guard let createdAt = createdAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: createdAt) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return createdAt
    }
    
    // Computed properties for the new views
    var isAdmin: Bool {
        // TODO: Compare with current user ID
        return false
    }
    
    static let sampleGroup = Group(
        id: "sample-group-id",
        name: "Sample Group",
        description: "This is a sample group description",
        members: [],
        admins: [],
        events: [],
        createdAt: "2024-01-01T00:00:00.000Z",
        updatedAt: "2024-01-01T00:00:00.000Z"
    )
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
        case members
        case admins
        case events
        case createdAt
        case updatedAt
    }
}

struct GroupResponse: Codable {
    let success: Bool
    let message: String?
    let data: GroupData
}

struct GroupData: Codable {
    let group: Group
}

struct GroupsResponse: Codable {
    let success: Bool
    let message: String?
    let data: GroupsData
}

struct GroupsData: Codable {
    let groups: [Group]
}

struct GroupInviteResponse: Codable {
    let success: Bool
    let message: String?
    let data: GroupInviteData
}

struct GroupInviteData: Codable {
    let inviteLink: String
    let group: Group
}

struct JoinGroupResponse: Codable {
    let success: Bool
    let message: String?
    let data: JoinGroupData
}

struct JoinGroupData: Codable {
    let group: Group
    let user: User
}
