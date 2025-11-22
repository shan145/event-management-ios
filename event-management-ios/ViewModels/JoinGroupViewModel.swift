import Foundation

@MainActor
class JoinGroupViewModel: ObservableObject {
    @Published var groupCode = ""
    @Published var isLoading = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let apiService = APIService.shared
    
    var isFormValid: Bool {
        !groupCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func joinGroup() async {
        guard isFormValid else { return }
        
        guard let userId = AuthManager.shared.currentUser?.id else {
            errorMessage = "You must be logged in to join a group"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let response = try await apiService.joinGroup(
                token: groupCode.trimmingCharacters(in: .whitespacesAndNewlines),
                userId: userId
            )
            
            // Success
            isSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func resetForm() {
        groupCode = ""
        isSuccess = false
        errorMessage = nil
        showError = false
    }
}
