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
    
    @Published var selectedDate = Date() {
        didSet {
            date = dateFormatter.string(from: selectedDate)
        }
    }
    @Published var selectedTime = Date() {
        didSet {
            time = timeFormatter.string(from: selectedTime)
        }
    }
    
    private let apiService = APIService.shared
    private let dateFormatter = DateFormatter()
    private let timeFormatter = DateFormatter()
    
    init() {
        setupFormatters()
    }
    
    private func setupFormatters() {
        // Set up date formatter for Eastern Time
        dateFormatter.dateFormat = "MMM d, yyyy"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        
        // Set up time formatter for Eastern Time  
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.timeZone = TimeZone(identifier: "America/New_York")
    }
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !date.isEmpty &&
        !time.isEmpty
    }
    
    func loadEvent(event: Event) {
        title = event.title
        description = event.description ?? ""
        location = event.location?.name ?? ""
        maxAttendees = event.maxAttendees?.description ?? ""
        guests = "0" // Default value
        notifyGroup = false // Default value
        
        // Parse the existing date and time strings
        if let parsedDateTime = parseEventDateTime(date: event.date, time: event.time) {
            selectedDate = parsedDateTime
            selectedTime = parsedDateTime
            // The didSet observers will automatically update date and time strings
        } else {
            // Fallback to current date/time in ET if parsing fails
            let now = Date()
            selectedDate = now
            selectedTime = now
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
                date: formatDateForAPI(),
                time: formatTimeForAPI(),
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
    
    
    private func parseEventDateTime(date: String, time: String) -> Date? {
        // First, try to parse the date as an ISO timestamp (which seems to be the case)
        let isoFormatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        ]
        
        // Try parsing the date field as ISO timestamp first
        for format in isoFormatters {
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = format
            inputFormatter.timeZone = TimeZone(identifier: "UTC")
            
            if let parsedDate = inputFormatter.date(from: date) {
                return parsedDate
            }
        }
        
        // If that fails, try combining date and time strings
        let dateTime = "\(date) \(time)"
        let combinedFormatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in combinedFormatters {
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = format
            inputFormatter.timeZone = TimeZone(identifier: "UTC")
            
            if let parsedDate = inputFormatter.date(from: dateTime) {
                return parsedDate
            }
        }
        
        return nil
    }
    
    private func formatDateForAPI() -> String {
        let apiDateFormatter = DateFormatter()
        apiDateFormatter.dateFormat = "yyyy-MM-dd"
        apiDateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        return apiDateFormatter.string(from: selectedDate)
    }
    
    private func formatTimeForAPI() -> String {
        let apiTimeFormatter = DateFormatter()
        apiTimeFormatter.dateFormat = "HH:mm"
        apiTimeFormatter.timeZone = TimeZone(identifier: "America/New_York")
        return apiTimeFormatter.string(from: selectedTime)
    }
}
