import Foundation
import SwiftUI

@MainActor
class GroupAdminViewModel: ObservableObject {
    @Published var members: [User] = []
    @Published var admins: [User] = []
    @Published var pendingInvites: [GroupInvite] = []
    
    // Group settings
    @Published var allowMemberInvites = true
    @Published var requireAdminApproval = false
    @Published var isPublicGroup = false
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    private let apiService = APIService.shared
    
    func loadGroupData(groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getGroup(id: groupId)
            
            members = response.data.group.members ?? []
            // Combine main admin and group admins
            var allAdmins: [User] = []
            if let mainAdmin = response.data.group.adminId {
                allAdmins.append(mainAdmin)
            }
            if let groupAdmins = response.data.group.groupAdmins {
                // Extract User objects from GroupAdmin enum
                let groupAdminUsers = groupAdmins.compactMap { $0.user }
                allAdmins.append(contentsOf: groupAdminUsers)
            }
            admins = allAdmins
            
            // Load pending invites
            let invitesResponse = try await apiService.getGroupInvites(groupId: groupId)
            pendingInvites = invitesResponse.data.invites
            
            // Load group settings
            loadGroupSettings(response.data.group)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func removeMember(userId: String, groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.removeGroupMember(userId: userId, groupId: groupId)
            
            // Refresh group data
            await loadGroupData(groupId: groupId)
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func revokeInvite(inviteId: String, groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.revokeGroupInvite(inviteId: inviteId, groupId: groupId)
            
            // Refresh invites
            let invitesResponse = try await apiService.getGroupInvites(groupId: groupId)
            pendingInvites = invitesResponse.data.invites
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateGroupSettings(groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let settings = GroupSettings(
                allowMemberInvites: allowMemberInvites,
                requireAdminApproval: requireAdminApproval,
                isPublicGroup: isPublicGroup
            )
            
            let response = try await apiService.updateGroupSettings(groupId: groupId, settings: settings)
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteGroup(groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.deleteGroup(id: groupId)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadGroupSettings(_ group: Group) {
        // Load group settings from the group object
        // This would typically come from the API response
        allowMemberInvites = true // Default value
        requireAdminApproval = false // Default value
        isPublicGroup = false // Default value
    }
}

// MARK: - Group Settings Model

struct GroupSettings: Codable {
    let allowMemberInvites: Bool
    let requireAdminApproval: Bool
    let isPublicGroup: Bool
}

// MARK: - Group Invite Model

struct GroupInvite: Codable, Identifiable {
    let id: String
    let email: String
    let invitedAt: String
    let expiresAt: String
    let status: InviteStatus
    
    var formattedInvitedDate: String {
        if let date = ISO8601DateFormatter().date(from: invitedAt) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return invitedAt
    }
    
    var isExpired: Bool {
        guard let expiryDate = ISO8601DateFormatter().date(from: expiresAt) else { return false }
        return Date() > expiryDate
    }
}

enum InviteStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
}
