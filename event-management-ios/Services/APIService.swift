import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(String)
    case unauthorized
    case forbidden
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        }
    }
}

// MARK: - Request Body Structs

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
}

struct CreateGroupRequest: Codable {
    let name: String
}

struct CreateEventRequest: Codable {
    let title: String
    let description: String?
    let location: String?
    let date: String
    let time: String
    let maxAttendees: Int?
    let guests: Int
    let notifyGroup: Bool
}

struct UpdateEventRequest: Codable {
    let title: String
    let description: String?
    let location: String?
    let date: String
    let time: String
    let maxAttendees: Int?
    let guests: Int
}

struct UpdateUserRequest: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
}

struct UserIdRequest: Codable {
    let userId: String
}

struct JoinGroupRequest: Codable {
    let userId: String
}

struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
}

class APIService: ObservableObject {
    static let shared = APIService()
    
    // Use localhost for development
    private let baseURL = "http://localhost:8080/api"
    private var authToken: String?
    
    private init() {}
    
    // MARK: - Debug/Test Methods
    
    func testConnection() async throws -> String {
        // Try multiple localhost variations
        let testURLs = [
            "http://localhost:8080/api/auth/login",
            "http://127.0.0.1:8080/api/auth/login"
        ]
        
        for (index, urlString) in testURLs.enumerated() {
            print("🔍 Testing connection attempt \(index + 1) to: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                print("❌ Invalid URL: \(urlString)")
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0 // 10 second timeout
            
            do {
                print("📡 Making request...")
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ No HTTP response")
                    continue
                }
                
                let responseString = String(data: data, encoding: .utf8) ?? "No response data"
                print("✅ Response: Status \(httpResponse.statusCode), Data: \(responseString)")
                return "Success! Using: \(urlString)\nStatus: \(httpResponse.statusCode), Response: \(responseString)"
                
            } catch {
                print("❌ Error with \(urlString): \(error.localizedDescription)")
                if index == testURLs.count - 1 {
                    return "All connection attempts failed. Last error: \(error.localizedDescription)"
                }
            }
        }
        
        return "No working connection found"
    }
    
    // MARK: - Authentication
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    private func createRequest(url: URL, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    private func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "API", code: -1, userInfo: nil))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError
                }
            case 401:
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            default:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.message ?? "Server error")
                } else {
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            if error is APIError {
                throw error
            } else {
                throw APIError.networkError(error)
            }
        }
    }
    
    // MARK: - Authentication Endpoints
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        let requestBody = LoginRequest(email: email, password: password)
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "POST", body: body)
        return try await performRequest(request, responseType: AuthResponse.self)
    }
    
    func signup(firstName: String, lastName: String, email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/signup")!
        let requestBody = SignupRequest(firstName: firstName, lastName: lastName, email: email, password: password)
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "POST", body: body)
        return try await performRequest(request, responseType: AuthResponse.self)
    }
    
    func createAdmin(firstName: String, lastName: String, email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/create-admin")!
        let requestBody = SignupRequest(firstName: firstName, lastName: lastName, email: email, password: password)
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "POST", body: body)
        return try await performRequest(request, responseType: AuthResponse.self)
    }
    
    func getCurrentUser() async throws -> UserResponse {
        let url = URL(string: "\(baseURL)/auth/me")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: UserResponse.self)
    }
    
    // MARK: - User Endpoints
    
    func getUsers() async throws -> UsersResponse {
        let url = URL(string: "\(baseURL)/users")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: UsersResponse.self)
    }
    
    func getUser(id: String) async throws -> UserResponse {
        let url = URL(string: "\(baseURL)/users/\(id)")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: UserResponse.self)
    }
    
    func updateUser(id: String, firstName: String? = nil, lastName: String? = nil, email: String? = nil) async throws -> UserResponse {
        let url = URL(string: "\(baseURL)/users/\(id)")!
        let requestBody = UpdateUserRequest(firstName: firstName, lastName: lastName, email: email)
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "PUT", body: body)
        return try await performRequest(request, responseType: UserResponse.self)
    }
    
    func deleteUser(id: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/users/\(id)")!
        let request = createRequest(url: url, method: "DELETE")
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    // MARK: - Group Endpoints
    
    func getGroups() async throws -> GroupsResponse {
        let url = URL(string: "\(baseURL)/groups")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: GroupsResponse.self)
    }
    
    func createGroup(name: String) async throws -> GroupResponse {
        let url = URL(string: "\(baseURL)/groups")!
        let requestBody = CreateGroupRequest(name: name)
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "POST", body: body)
        return try await performRequest(request, responseType: GroupResponse.self)
    }
    
    func getGroup(id: String) async throws -> GroupResponse {
        let url = URL(string: "\(baseURL)/groups/\(id)")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: GroupResponse.self)
    }
    
    func generateGroupInvite(groupId: String) async throws -> GroupInviteResponse {
        let url = URL(string: "\(baseURL)/groups/\(groupId)/invite")!
        let request = createRequest(url: url, method: "POST")
        return try await performRequest(request, responseType: GroupInviteResponse.self)
    }
    
    func deleteGroup(id: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/groups/\(id)")!
        let request = createRequest(url: url, method: "DELETE")
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    // MARK: - Event Endpoints
    
    func getEvents() async throws -> EventsResponse {
        let url = URL(string: "\(baseURL)/events")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: EventsResponse.self)
    }
    
    func getEvent(id: String) async throws -> EventResponse {
        let url = URL(string: "\(baseURL)/events/\(id)")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: EventResponse.self)
    }
    
    func createEvent(groupId: String, title: String, description: String?, location: String?, date: String, time: String, maxAttendees: Int?, guests: Int = 0, notifyGroup: Bool = false) async throws -> EventResponse {
        let url = URL(string: "\(baseURL)/groups/\(groupId)/events")!
        let requestBody = CreateEventRequest(
            title: title,
            description: description,
            location: location,
            date: date,
            time: time,
            maxAttendees: maxAttendees,
            guests: guests,
            notifyGroup: notifyGroup
        )
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "POST", body: body)
        return try await performRequest(request, responseType: EventResponse.self)
    }
    
    func updateEvent(id: String, title: String, description: String?, location: String?, date: String, time: String, maxAttendees: Int?, guests: Int = 0) async throws -> EventResponse {
        let url = URL(string: "\(baseURL)/events/\(id)")!
        let requestBody = UpdateEventRequest(
            title: title,
            description: description,
            location: location,
            date: date,
            time: time,
            maxAttendees: maxAttendees,
            guests: guests
        )
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "PUT", body: body)
        return try await performRequest(request, responseType: EventResponse.self)
    }
    
    func deleteEvent(id: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/events/\(id)")!
        let request = createRequest(url: url, method: "DELETE")
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    func joinEvent(id: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/events/\(id)/join")!
        let request = createRequest(url: url, method: "POST")
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    func approveEventAttendee(eventId: String, userId: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/events/\(eventId)/approve")!
        let requestBody = UserIdRequest(userId: userId)
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "POST", body: body)
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    func rejectEventAttendee(eventId: String, userId: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/events/\(eventId)/nogo")!
        let requestBody = UserIdRequest(userId: userId)
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "POST", body: body)
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    func moveToWaitlist(eventId: String, userId: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/events/\(eventId)/move-to-waitlist")!
        let requestBody = UserIdRequest(userId: userId)
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "POST", body: body)
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    func getEventAttendees(eventId: String) async throws -> EventAttendeesResponse {
        let url = URL(string: "\(baseURL)/events/\(eventId)/attendees")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: EventAttendeesResponse.self)
    }
    
    // MARK: - Join Group Endpoints
    
    func getGroupFromInvite(token: String) async throws -> GroupInviteResponse {
        let url = URL(string: "\(baseURL)/join/\(token)")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: GroupInviteResponse.self)
    }
    
    func joinGroup(token: String, userId: String) async throws -> JoinGroupResponse {
        let url = URL(string: "\(baseURL)/join/\(token)")!
        let requestBody = JoinGroupRequest(userId: userId)
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "POST", body: body)
        return try await performRequest(request, responseType: JoinGroupResponse.self)
    }
    
    // MARK: - User Profile Endpoints
    
    func updateProfile(firstName: String, lastName: String) async throws -> UserResponse {
        let url = URL(string: "\(baseURL)/users/profile")!
        let requestBody = UpdateUserRequest(
            firstName: firstName,
            lastName: lastName,
            email: nil
        )
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "PUT", body: body)
        return try await performRequest(request, responseType: UserResponse.self)
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/users/password")!
        let requestBody = ChangePasswordRequest(
            currentPassword: currentPassword,
            newPassword: newPassword
        )
        let body = try JSONEncoder().encode(requestBody)
        let request = createRequest(url: url, method: "PUT", body: body)
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    func updatePreferences(preferences: UserPreferences) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/users/preferences")!
        let body = try JSONEncoder().encode(preferences)
        let request = createRequest(url: url, method: "PUT", body: body)
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    // MARK: - Notification Endpoints
    
    func getNotifications() async throws -> NotificationsResponse {
        let url = URL(string: "\(baseURL)/notifications")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: NotificationsResponse.self)
    }
    
    func markNotificationAsRead(notificationId: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/notifications/\(notificationId)/read")!
        let request = createRequest(url: url, method: "PUT")
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    func markAllNotificationsAsRead() async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/notifications/read-all")!
        let request = createRequest(url: url, method: "PUT")
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    // MARK: - Group Admin Endpoints
    
    func getGroupInvites(groupId: String) async throws -> GroupInvitesResponse {
        let url = URL(string: "\(baseURL)/groups/\(groupId)/invites")!
        let request = createRequest(url: url)
        return try await performRequest(request, responseType: GroupInvitesResponse.self)
    }
    
    func revokeGroupInvite(inviteId: String, groupId: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/groups/\(groupId)/invites/\(inviteId)")!
        let request = createRequest(url: url, method: "DELETE")
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    func removeGroupMember(userId: String, groupId: String) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/groups/\(groupId)/members/\(userId)")!
        let request = createRequest(url: url, method: "DELETE")
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
    
    func updateGroupSettings(groupId: String, settings: GroupSettings) async throws -> SuccessResponse {
        let url = URL(string: "\(baseURL)/groups/\(groupId)/settings")!
        let body = try JSONEncoder().encode(settings)
        let request = createRequest(url: url, method: "PUT", body: body)
        return try await performRequest(request, responseType: SuccessResponse.self)
    }
}

// MARK: - Response Types

struct ErrorResponse: Codable {
    let success: Bool
    let message: String?
}

struct SuccessResponse: Codable {
    let success: Bool
    let message: String?
}

struct UsersResponse: Codable {
    let success: Bool
    let message: String?
    let data: UsersData
}

struct UsersData: Codable {
    let users: [User]
}

// UserResponse and UserData are defined in Models/User.swift

struct NotificationsResponse: Codable {
    let success: Bool
    let message: String?
    let data: NotificationsData
}

struct NotificationsData: Codable {
    let notifications: [AppNotification]
}

struct GroupInvitesResponse: Codable {
    let success: Bool
    let message: String?
    let data: GroupInvitesData
}

struct GroupInvitesData: Codable {
    let invites: [GroupInvite]
}
