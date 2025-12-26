import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let eventId: String
    let senderId: SenderInfo
    let content: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case eventId
        case senderId
        case content
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        eventId = try container.decode(String.self, forKey: .eventId)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        
        senderId = try container.decode(SenderInfo.self, forKey: .senderId)
    }
    
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .none
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        let fallbackFormatter = ISO8601DateFormatter()
        if let date = fallbackFormatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .none
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return createdAt
    }
    
    func isFromCurrentUser(currentUserId: String?) -> Bool {
        guard let currentUserId = currentUserId else {
            return false
        }
        return senderId.id == currentUserId
    }
}

struct SenderInfo: Codable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

struct MessagesResponse: Codable {
    let success: Bool
    let message: String?
    let data: MessagesData
}

struct MessagesData: Codable {
    let messages: [Message]
    let hasMore: Bool
}

struct SendMessageRequest: Codable {
    let content: String
}

struct SendMessageResponse: Codable {
    let success: Bool
    let message: String?
    let data: MessageData
}

struct MessageData: Codable {
    let message: Message
}

struct UnreadCountsResponse: Codable {
    let success: Bool
    let data: UnreadCountsData
}

struct UnreadCountsData: Codable {
    let unreadCounts: [String: Int]
}

