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
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // TODO: We need a userId for joining groups. For now, we'll use a placeholder
            // In a real app, you'd get the current user's ID from AuthManager
            let userId = "placeholder-user-id"
            
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
