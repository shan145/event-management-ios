import Foundation
import SwiftUI

@MainActor
class EditEventViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var location = ""
    @Published var date = ""
    @Published var time = ""
    @Published var maxAttendees = ""
    @Published var guests = "0"
    @Published var notifyGroup = false
    
    @Published var showingDatePicker = false
    @Published var showingTimePicker = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    @Published var selectedDate = Date()
    @Published var selectedTime = Date()
    
    private let apiService = APIService.shared
    private let dateFormatter = DateFormatter()
    private let timeFormatter = DateFormatter()
    
    init() {
        setupFormatters()
    }
    
    private func setupFormatters() {
        dateFormatter.dateStyle = .medium
        timeFormatter.timeStyle = .short
    }
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !date.isEmpty &&
        !time.isEmpty
    }
    
    func loadEvent(event: Event) {
        title = event.title
        description = event.description ?? ""
        location = event.location ?? ""
        date = event.date
        time = event.time
        maxAttendees = event.maxAttendees?.description ?? ""
        guests = "0" // Default value
        notifyGroup = false // Default value
        
        // Parse existing date and time
        if let eventDate = parseDate(event.date) {
            selectedDate = eventDate
        }
        
        if let eventTime = parseTime(event.time) {
            selectedTime = eventTime
        }
    }
    
    func updateEvent(eventId: String) async {
        guard isValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let maxAttendeesInt = maxAttendees.isEmpty ? nil : Int(maxAttendees)
            let guestsInt = Int(guests) ?? 0
            
            let response = try await apiService.updateEvent(
                id: eventId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                time: time,
                maxAttendees: maxAttendeesInt,
                guests: guestsInt
            )
            
            print("✅ Successfully updated event: \(response.data.event.title)")
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to update event: \(error)")
        }
        
        isLoading = false
    }
    
    func deleteEvent(eventId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.deleteEvent(id: eventId)
            print("✅ Successfully deleted event: \(response.message)")
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to delete event: \(error)")
        }
        
        isLoading = false
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.date(from: dateString)
    }
    
    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.date(from: timeString)
    }
}
