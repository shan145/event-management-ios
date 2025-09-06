import Foundation
import SwiftUI

@MainActor
class EventDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var eventDetails: Event?
    
    private let apiService = APIService.shared
    
    func loadEventDetails(eventId: String) {
        Task {
            await fetchEventDetails(eventId: eventId)
        }
    }
    
    func joinEvent(eventId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.joinEventWaitlist(id: eventId)
            print("✅ Successfully joined event: \(response.message)")
            
            // Refresh event details
            await fetchEventDetails(eventId: eventId)
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to join event: \(error)")
        }
        
        isLoading = false
    }
    
    func leaveEvent(eventId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Note: The API might not have a leave event endpoint
            // We'll need to implement this based on your server's API
            print("🔄 Leaving event - API endpoint needed")
            
            // For now, just refresh the event details
            await fetchEventDetails(eventId: eventId)
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to leave event: \(error)")
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
    
    private func fetchEventDetails(eventId: String) async {
        do {
            let response = try await apiService.getEvent(id: eventId)
            eventDetails = response.data.event
            print("✅ Loaded event details: \(response.data.event.title)")
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to load event details: \(error)")
        }
    }
    
    func approveAttendee(eventId: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.approveEventAttendee(eventId: eventId, userId: userId)
            print("✅ Successfully approved attendee: \(response.message)")
            
            // Refresh event details
            await fetchEventDetails(eventId: eventId)
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to approve attendee: \(error)")
        }
        
        isLoading = false
    }
    
    func rejectAttendee(eventId: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.rejectEventAttendee(eventId: eventId, userId: userId)
            print("✅ Successfully rejected attendee: \(response.message)")
            
            // Refresh event details
            await fetchEventDetails(eventId: eventId)
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to reject attendee: \(error)")
        }
        
        isLoading = false
    }
    
    func moveToWaitlist(eventId: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.moveToWaitlist(eventId: eventId, userId: userId)
            print("✅ Successfully moved to waitlist: \(response.message)")
            
            // Refresh event details
            await fetchEventDetails(eventId: eventId)
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to move to waitlist: \(error)")
        }
        
        isLoading = false
    }
}
