import Foundation

// Simple group reference for groupAdminOf field
struct GroupReference: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
    }
}

struct User: Codable, Identifiable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let role: String?
    let groups: [GroupReference]?
    let groupAdminOf: [GroupReference]?
    let createdAt: String?
    let updatedAt: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        email = try container.decode(String.self, forKey: .email)
        
        // Optional fields that might not be present in all responses
        role = try container.decodeIfPresent(String.self, forKey: .role)
        groups = try container.decodeIfPresent([GroupReference].self, forKey: .groups)
        groupAdminOf = try container.decodeIfPresent([GroupReference].self, forKey: .groupAdminOf)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var isAdmin: Bool {
        role == "admin"
    }
    
    var isGroupAdmin: Bool {
        groupAdminOf != nil && !groupAdminOf!.isEmpty
    }
    
    var isSuperAdmin: Bool {
        role == "admin"
    }
    
    func isAdminOfGroup(_ groupId: String) -> Bool {
        // Super admins have admin privileges for all groups
        isAdmin || (groupAdminOf?.contains { $0.id == groupId } == true)
    }
    
    var canCreateEvents: Bool {
        isAdmin || isGroupAdmin
    }
    
    var canCreateGroups: Bool {
        isSuperAdmin
    }
    
    // Custom initializer for creating User instances
    init(id: String, firstName: String, lastName: String, email: String, role: String? = nil, groups: [GroupReference]? = nil, groupAdminOf: [GroupReference]? = nil, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.groups = groups
        self.groupAdminOf = groupAdminOf
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
        case role
        case groups
        case groupAdminOf
        case createdAt
        case updatedAt
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String?
    let data: AuthData
}

struct AuthData: Codable {
    let user: User
    let token: String
}

struct UserResponse: Codable {
    let success: Bool
    let message: String?
    let data: UserData
}

struct UserData: Codable {
    let user: User
}
