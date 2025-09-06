import Foundation

@MainActor
class CreateEventViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var location = ""
    @Published var selectedDate = Date()
    @Published var selectedTime = Date()
    @Published var isUnlimitedCapacity = true
    @Published var maxAttendees = ""
    @Published var selectedGroupId = ""
    @Published var availableGroups: [Group] = []
    @Published var preSelectedGroup: Group? = nil
    @Published var isLoading = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let apiService = APIService.shared
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: selectedTime)
    }
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedDate >= Calendar.current.startOfDay(for: Date()) &&
        !selectedGroupId.isEmpty
    }
    
    func setPreSelectedGroup(_ group: Group) {
        self.preSelectedGroup = group
        self.selectedGroupId = group.id
    }
    
    func createEvent() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // Format date and time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: selectedDate)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let timeString = timeFormatter.string(from: selectedTime)
            
            // Parse max attendees
            var maxAttendeesInt: Int?
            if !isUnlimitedCapacity && !maxAttendees.isEmpty {
                maxAttendeesInt = Int(maxAttendees)
            }
            
            let _ = try await apiService.createEvent(
                groupId: selectedGroupId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
                date: dateString,
                time: timeString,
                maxAttendees: maxAttendeesInt
            )
            
            // Success
            isSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func loadAvailableGroups() async {
        do {
            let response = try await apiService.getUserGroups()
            // Filter to only show groups where the user is an admin
            if let currentUser = AuthManager.shared.currentUser {
                if currentUser.isAdmin {
                    // Super admins can create events in any group
                    availableGroups = response.data.groups
                } else {
                    // Group admins can only create events in their own groups
                    availableGroups = response.data.groups.filter { group in
                        currentUser.isAdminOfGroup(group.id)
                    }
                }
            } else {
                availableGroups = []
            }
        } catch {
            print("Failed to load groups: \(error)")
        }
    }
    
    func resetForm() {
        title = ""
        description = ""
        location = ""
        selectedDate = Date()
        selectedTime = Date()
        isUnlimitedCapacity = true
        maxAttendees = ""
        selectedGroupId = ""
        isSuccess = false
        errorMessage = nil
        showError = false
    }
}
