import Foundation

// Enum to handle group admins as either User objects or string IDs
enum GroupAdmin: Codable, Equatable {
    case user(User)
    case id(String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let user = try? container.decode(User.self) {
            self = .user(user)
        } else if let id = try? container.decode(String.self) {
            self = .id(id)
        } else {
            throw DecodingError.typeMismatch(GroupAdmin.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected User object or String ID"))
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

struct Group: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let adminId: User?
    let groupAdmins: [GroupAdmin]?
    let members: [User]?
    let tags: [String]?
    let inviteToken: String?
    let createdAt: String?
    let eventCount: Int?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        adminId = try container.decodeIfPresent(User.self, forKey: .adminId)
        
        // Handle groupAdmins as either User objects or string IDs
        if let groupAdminsArray = try? container.decode([User].self, forKey: .groupAdmins) {
            groupAdmins = groupAdminsArray.map { GroupAdmin.user($0) }
        } else if let groupAdminsIds = try? container.decode([String].self, forKey: .groupAdmins) {
            groupAdmins = groupAdminsIds.map { GroupAdmin.id($0) }
        } else {
            groupAdmins = nil
        }
        
        members = try container.decodeIfPresent([User].self, forKey: .members)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        inviteToken = try container.decodeIfPresent(String.self, forKey: .inviteToken)
        eventCount = try container.decodeIfPresent(Int.self, forKey: .eventCount)
        
        // Handle createdAt as either String or Date
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = createdAtString
        } else if let createdAtDate = try? container.decode(Date.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.string(from: createdAtDate)
        } else {
            createdAt = nil
        }
    }
    
    var memberCount: Int {
        members?.count ?? 0
    }
    
    var totalEventCount: Int {
        return self.eventCount ?? 0
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
        adminId: nil,
        groupAdmins: [],
        members: [],
        tags: [],
        inviteToken: "sample-token",
        createdAt: "2024-01-01T00:00:00.000Z",
        eventCount: 0
    )
    
    // Custom initializer for creating Group instances
    init(id: String, name: String, adminId: User?, groupAdmins: [GroupAdmin]?, members: [User]?, tags: [String]?, inviteToken: String?, createdAt: String?, eventCount: Int?) {
        self.id = id
        self.name = name
        self.adminId = adminId
        self.groupAdmins = groupAdmins
        self.members = members
        self.tags = tags
        self.inviteToken = inviteToken
        self.createdAt = createdAt
        self.eventCount = eventCount
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case adminId
        case groupAdmins
        case members
        case tags
        case inviteToken
        case createdAt
        case eventCount
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
