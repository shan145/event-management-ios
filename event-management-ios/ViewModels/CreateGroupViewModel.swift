import Foundation

@MainActor
class CreateGroupViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var isLoading = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let apiService = APIService.shared
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func createGroup() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let response = try await apiService.createGroup(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
            
            // Success
            isSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func resetForm() {
        name = ""
        description = ""
        isSuccess = false
        errorMessage = nil
        showError = false
    }
}
