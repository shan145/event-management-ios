import Foundation

@MainActor
class CreateEventViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var location = ""
    @Published var selectedDate = Date()
    @Published var selectedTime = Date()
    @Published var selectedEndDate: Date? = nil
    @Published var selectedEndTime: Date? = nil
    @Published var isUnlimitedCapacity = true
    @Published var maxAttendees = ""
    @Published var guests = ""
    @Published var notifyGroupMembers = false
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
    
    func duplicateEvent(from event: Event) {
        // Pre-fill all fields from the existing event
        self.title = event.title
        self.description = event.description ?? ""
        self.location = event.location?.name ?? ""
        
        // Parse the event date and time
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        
        // Parse date
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let eventDate = dateFormatter.date(from: event.date) {
            self.selectedDate = eventDate
        }
        
        // Parse time
        dateFormatter.dateFormat = "HH:mm"
        if let eventTime = dateFormatter.date(from: event.time) {
            // Combine date and time for the time picker
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: eventTime)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            combinedComponents.timeZone = TimeZone(identifier: "America/New_York")
            
            if let combinedDate = calendar.date(from: combinedComponents) {
                self.selectedTime = combinedDate
            }
        }
        
        // Parse end date and time if available
        if let endDateStr = event.endDate, let endTimeStr = event.endTime {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let eventEndDate = dateFormatter.date(from: endDateStr) {
                self.selectedEndDate = eventEndDate
            }
            
            dateFormatter.dateFormat = "HH:mm"
            if let eventEndTime = dateFormatter.date(from: endTimeStr) {
                let calendar = Calendar.current
                let endDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedEndDate ?? selectedDate)
                let endTimeComponents = calendar.dateComponents([.hour, .minute], from: eventEndTime)
                
                var combinedEndComponents = DateComponents()
                combinedEndComponents.year = endDateComponents.year
                combinedEndComponents.month = endDateComponents.month
                combinedEndComponents.day = endDateComponents.day
                combinedEndComponents.hour = endTimeComponents.hour
                combinedEndComponents.minute = endTimeComponents.minute
                combinedEndComponents.timeZone = TimeZone(identifier: "America/New_York")
                
                if let combinedEndDate = calendar.date(from: combinedEndComponents) {
                    self.selectedEndTime = combinedEndDate
                }
            }
        }
        
        // Set capacity settings
        if let maxCapacity = event.maxAttendees, maxCapacity > 0 {
            self.isUnlimitedCapacity = false
            self.maxAttendees = String(maxCapacity)
        } else {
            self.isUnlimitedCapacity = true
            self.maxAttendees = ""
        }
        
        // Set guests
        self.guests = String(event.guests)
        
        // Don't auto-enable notifications for duplicated events
        self.notifyGroupMembers = false
        
        // Set the group
        switch event.groupId {
        case .group(let group):
            setPreSelectedGroup(group)
        case .populatedGroup(let popGroup):
            // Create a minimal Group from PopulatedGroup
            let group = Group(
                id: popGroup.id,
                name: popGroup.name,
                adminId: nil,
                groupAdmins: nil,
                members: nil, // PopulatedGroup.members is [String]?, but Group.members is [User]?
                tags: nil,
                inviteToken: nil,
                createdAt: nil,
                eventCount: nil
            )
            setPreSelectedGroup(group)
        case .id(let groupId):
            self.selectedGroupId = groupId
            // For ID-only case, we need to find the group in available groups
            // This will be handled when loadAvailableGroups() is called
        }
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
            
            // Format end date and time if provided
            let endDateString: String?
            let endTimeString: String?
            if let endDate = selectedEndDate, let endTime = selectedEndTime {
                endDateString = dateFormatter.string(from: endDate)
                endTimeString = timeFormatter.string(from: endTime)
            } else {
                endDateString = nil
                endTimeString = nil
            }
            
            // Parse max attendees
            var maxAttendeesInt: Int?
            if !isUnlimitedCapacity && !maxAttendees.isEmpty {
                maxAttendeesInt = Int(maxAttendees)
            }
            
            // Parse guests
            let guestsInt = Int(guests.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            
            let _ = try await apiService.createEvent(
                groupId: selectedGroupId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
                date: dateString,
                time: timeString,
                endDate: endDateString,
                endTime: endTimeString,
                maxAttendees: maxAttendeesInt,
                guests: guestsInt,
                notifyGroup: notifyGroupMembers
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
            
            // If we have a selectedGroupId but no preSelectedGroup (from duplication), find the group
            if preSelectedGroup == nil && !selectedGroupId.isEmpty {
                if let foundGroup = availableGroups.first(where: { $0.id == selectedGroupId }) {
                    setPreSelectedGroup(foundGroup)
                }
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
        selectedEndDate = nil
        selectedEndTime = nil
        isUnlimitedCapacity = true
        maxAttendees = ""
        selectedGroupId = ""
        isSuccess = false
        errorMessage = nil
        showError = false
    }
}
