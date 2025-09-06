import SwiftUI

struct EditEventView: View {
    let event: Event
    let onEventUpdated: (() -> Void)?
    @StateObject private var viewModel = EditEventViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    init(event: Event, onEventUpdated: (() -> Void)? = nil) {
        self.event = event
        self.onEventUpdated = onEventUpdated
    }
    
    var body: some View {
        VStack {
            // Custom Header
            HStack {
                cancelButton
                
                Spacer()
                
                Text("Edit Event")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                saveButton
            }
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 24) {
                    eventDetailsSection
                    dateTimeSection
                    capacitySection
                    notificationSection
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .sheet(isPresented: $viewModel.showingDatePicker) {
                DatePickerSheet(
                    title: "Select Date",
                    date: $viewModel.selectedDate,
                    isDate: true
                )
            }
            .sheet(isPresented: $viewModel.showingTimePicker) {
                DatePickerSheet(
                    title: "Select Time",
                    date: $viewModel.selectedTime,
                    isDate: false
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .onAppear {
                viewModel.loadEvent(event: event)
            }
        }
    }
    
    // MARK: - Supporting Views
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date & Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Button(action: {
                        viewModel.showingDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(viewModel.date)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Button(action: {
                        viewModel.showingTimePicker = true
                    }) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.green)
                            Text(viewModel.time)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var capacitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Capacity")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    AppTextField(
                        title: "Max Attendees",
                        placeholder: "No limit",
                        text: $viewModel.maxAttendees
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    AppTextField(
                        title: "Additional Guests",
                        placeholder: "0",
                        text: $viewModel.guests
                    )
                }
            }
        }
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle("Notify Group Members", isOn: $viewModel.notifyGroup)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            Task {
                await viewModel.updateEvent(eventId: event.id)
                if viewModel.errorMessage == nil {
                    onEventUpdated?()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .disabled(!viewModel.isValid || viewModel.isLoading)
    }
    
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            AppTextField(
                title: "Event Title",
                placeholder: "Enter event title",
                text: $viewModel.title
            )
            
            AppTextArea(
                title: "Event Description",
                placeholder: "Enter event description (optional)",
                text: $viewModel.description
            )
            
            AppTextField(
                title: "Location",
                placeholder: "Enter event location (optional)",
                text: $viewModel.location
            )
        }
    }
}

struct EditEventView_Previews: PreviewProvider {
    static var previews: some View {
        EditEventView(event: Event.sampleEvent)
    }
}
