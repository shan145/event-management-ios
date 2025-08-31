import Foundation
import SwiftUI

@MainActor
class GroupDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var groupDetails: Group?
    
    private let apiService = APIService.shared
    
    func loadGroupDetails(groupId: String) {
        Task {
            await fetchGroupDetails(groupId: groupId)
        }
    }
    
    func leaveGroup(groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Note: The API might not have a leave group endpoint
            // We'll need to implement this based on your server's API
            print("🔄 Leaving group - API endpoint needed")
            
            // For now, just refresh the group details
            await fetchGroupDetails(groupId: groupId)
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to leave group: \(error)")
        }
        
        isLoading = false
    }
    
    func deleteGroup(groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.deleteGroup(id: groupId)
            print("✅ Successfully deleted group: \(response.message)")
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to delete group: \(error)")
        }
        
        isLoading = false
    }
    
    func generateInviteLink(groupId: String) async -> String? {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.generateGroupInvite(groupId: groupId)
            print("✅ Successfully generated invite: \(response.data.inviteLink)")
            isLoading = false
            return response.data.inviteLink
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to generate invite: \(error)")
            isLoading = false
            return nil
        }
    }
    
    private func fetchGroupDetails(groupId: String) async {
        do {
            let response = try await apiService.getGroup(id: groupId)
            groupDetails = response.data.group
            print("✅ Loaded group details: \(response.data.group.name)")
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to load group details: \(error)")
        }
    }
}
