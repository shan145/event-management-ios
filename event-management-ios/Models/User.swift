import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let role: String?
    let groupAdminOf: [String]?
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
        groupAdminOf = try container.decodeIfPresent([String].self, forKey: .groupAdminOf)
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
    
    // Custom initializer for creating User instances
    init(id: String, firstName: String, lastName: String, email: String, role: String? = nil, groupAdminOf: [String]? = nil, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
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
