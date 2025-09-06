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
            // Combine main admin and group admins (deduplicate by user ID)
            var allAdmins: [User] = []
            var adminIds: Set<String> = []
            
            // Add main admin first
            if let mainAdmin = response.data.group.adminId {
                allAdmins.append(mainAdmin)
                adminIds.insert(mainAdmin.id)
            }
            
            // Add group admins, but skip if already added as main admin
            if let groupAdmins = response.data.group.groupAdmins {
                for groupAdmin in groupAdmins {
                    switch groupAdmin {
                    case .user(let user):
                        if !adminIds.contains(user.id) {
                            allAdmins.append(user)
                            adminIds.insert(user.id)
                        }
                    case .id(let userId):
                        if !adminIds.contains(userId) {
                            // If we only have an ID, we need to find the User object from members
                            if let userFromMembers = members.first(where: { $0.id == userId }) {
                                allAdmins.append(userFromMembers)
                                adminIds.insert(userId)
                            } else {
                                // Create a basic User object with just the ID if not found in members
                                // This shouldn't happen in normal operation, but provides fallback
                                print("Warning: Group admin with ID \(userId) not found in members list")
                            }
                        }
                    }
                }
            }
            admins = allAdmins
            
            // Note: This server doesn't have a pending invites system
            // It uses invite tokens instead
            pendingInvites = []
            
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
            let _ = try await apiService.removeGroupMember(userId: userId, groupId: groupId)
            
            // Refresh group data
            await loadGroupData(groupId: groupId)
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // Note: This server doesn't support revoking individual invites
    // It uses invite tokens that don't expire
    func revokeInvite(inviteId: String, groupId: String) async {
        // This functionality is not supported by the current server
        errorMessage = "Invite revocation is not supported. Use member management instead."
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
            
            let _ = try await apiService.updateGroupSettings(groupId: groupId, settings: settings)
            
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
            let _ = try await apiService.deleteGroup(id: groupId)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func searchUserByEmail(email: String) async -> User? {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        do {
            let response = try await apiService.searchUserByEmail(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            return response.data.user
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func addMemberByEmail(email: String, groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await apiService.addGroupMember(email: email, groupId: groupId)
            
            // Refresh group data
            await loadGroupData(groupId: groupId)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func makeUserAdmin(userId: String, groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await apiService.addGroupAdmin(userId: userId, groupId: groupId)
            
            // Refresh group data
            await loadGroupData(groupId: groupId)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func removeUserAdmin(userId: String, groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await apiService.removeGroupAdmin(userId: userId, groupId: groupId)
            
            // Refresh group data
            await loadGroupData(groupId: groupId)
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
