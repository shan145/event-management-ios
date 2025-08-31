import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let role: String
    let groupAdminOf: [String]?
    let createdAt: String?
    let updatedAt: String?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var isAdmin: Bool {
        role == "admin"
    }
    
    var isGroupAdmin: Bool {
        groupAdminOf != nil && !groupAdminOf!.isEmpty
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
