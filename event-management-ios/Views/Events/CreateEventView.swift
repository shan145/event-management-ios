import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateEventViewModel()
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Event Details Section
                    eventDetailsSection
                    
                    // Date & Time Section
                    dateTimeSection
                    
                    // Location Section
                    locationSection
                    
                    // Capacity Section
                    capacitySection
                    
                    // Description Section
                    descriptionSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
            .background(Color.appBackground)
            .navigationTitle("Create Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createEvent()
                            if viewModel.isSuccess {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                title: "Select Date",
                date: $viewModel.selectedDate,
                isDate: true
            )
        }
        .sheet(isPresented: $showTimePicker) {
            DatePickerSheet(
                title: "Select Time",
                date: $viewModel.selectedTime,
                isDate: false
            )
        }
    }
    
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Event Details")
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextField(
                title: "Event Title",
                placeholder: "Enter event title",
                text: $viewModel.title
            )
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Date & Time")
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Date")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                    
                    Button(action: { showDatePicker = true }) {
                        HStack {
                            Text(viewModel.formattedDate)
                                .foregroundColor(Color.appTextPrimary)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .padding(AppSpacing.md)
                        .background(Color.grey50)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Time")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                    
                    Button(action: { showTimePicker = true }) {
                        HStack {
                            Text(viewModel.formattedTime)
                                .foregroundColor(Color.appTextPrimary)
                            Spacer()
                            Image(systemName: "clock")
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .padding(AppSpacing.md)
                        .background(Color.grey50)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Location")
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextField(
                title: "Location",
                placeholder: "Enter event location (optional)",
                text: $viewModel.location
            )
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var capacitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Capacity")
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            HStack {
                Toggle("Unlimited Capacity", isOn: $viewModel.isUnlimitedCapacity)
                    .font(AppTypography.body2)
                    .foregroundColor(Color.appTextPrimary)
            }
            
            if !viewModel.isUnlimitedCapacity {
                AppTextField(
                    title: "Max Attendees",
                    placeholder: "Enter maximum number of attendees",
                    text: $viewModel.maxAttendees
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Description")
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextArea(
                title: "Event Description",
                placeholder: "Enter event description (optional)",
                text: $viewModel.description
            )
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
}

// MARK: - Supporting Views

struct DatePickerSheet: View {
    let title: String
    @Binding var date: Date
    let isDate: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if isDate {
                    DatePicker(
                        title,
                        selection: $date,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                } else {
                    DatePicker(
                        title,
                        selection: $date,
                        displayedComponents: .hourAndMinute
                    )
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateEventView()
}
