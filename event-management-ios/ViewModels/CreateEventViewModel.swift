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
        selectedDate >= Calendar.current.startOfDay(for: Date())
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
            
            // TODO: We need a groupId for creating events. For now, we'll use a placeholder
            // In a real app, you'd either select a group or create events without a group
            let groupId = "placeholder-group-id"
            
            let response = try await apiService.createEvent(
                groupId: groupId,
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
    
    func resetForm() {
        title = ""
        description = ""
        location = ""
        selectedDate = Date()
        selectedTime = Date()
        isUnlimitedCapacity = true
        maxAttendees = ""
        isSuccess = false
        errorMessage = nil
        showError = false
    }
}
