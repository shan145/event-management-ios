import SwiftUI
import UIKit

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateEventViewModel()
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    
    let preSelectedGroup: Group?
    let eventToDuplicate: Event?
    let onEventCreated: (() -> Void)?
    
    init(preSelectedGroup: Group? = nil, eventToDuplicate: Event? = nil, onEventCreated: (() -> Void)? = nil) {
        self.preSelectedGroup = preSelectedGroup
        self.eventToDuplicate = eventToDuplicate
        self.onEventCreated = onEventCreated
    }
    
    private func searchLocationInMaps(location: String) {
        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mapsURL = URL(string: "maps://?q=\(encodedLocation)")
        let webURL = URL(string: "https://maps.google.com/maps?q=\(encodedLocation)")
        
        if let mapsURL = mapsURL, UIApplication.shared.canOpenURL(mapsURL) {
            // Open in Apple Maps if available
            UIApplication.shared.open(mapsURL)
        } else if let webURL = webURL {
            // Fallback to Google Maps in browser
            UIApplication.shared.open(webURL)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Content
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Event Details Section
                    eventDetailsSection
                    
                    // Group Selection Section (only show if no pre-selected group)
                    if preSelectedGroup == nil {
                        groupSelectionSection
                    } else {
                        preSelectedGroupSection
                    }
                    
                    // Date & Time Section
                    dateTimeSection
                    
                    // Location Section
                    locationSection
                    
                    // Capacity Section
                    capacitySection
                    
                    // Description Section
                    descriptionSection
                    
                    // Notification Section
                    notificationSection
                    
                    // Spacer for bottom padding
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.xl)
            }
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .ignoresSafeArea(.container, edges: .bottom)
        .task {
            if let eventToDuplicate = eventToDuplicate {
                // Pre-fill all fields from the event to duplicate
                viewModel.duplicateEvent(from: eventToDuplicate)
                // Load available groups for admin users
                await viewModel.loadAvailableGroups()
            } else if let preSelectedGroup = preSelectedGroup {
                viewModel.setPreSelectedGroup(preSelectedGroup)
            } else {
                await viewModel.loadAvailableGroups()
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
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(TextButtonStyle())
                
                Spacer()
                
                Text(eventToDuplicate != nil ? "Duplicate Event" : "Create Event")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("Create") {
                    Task {
                        await viewModel.createEvent()
                        if viewModel.isSuccess {
                            onEventCreated?() // Trigger refresh callback
                            dismiss()
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.isFormValid || viewModel.isLoading || AuthManager.shared.currentUser?.canCreateEvents != true)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            
            Divider()
        }
        .background(Color.appSurface)
    }
    
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Event Details")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextField(
                title: "Event Title",
                placeholder: "Enter event title",
                text: $viewModel.title
            )
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var groupSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Group")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            if viewModel.availableGroups.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    if AuthManager.shared.currentUser?.isAdmin == true {
                        Text("No groups available")
                            .font(AppTypography.body2)
                            .foregroundColor(Color.appTextSecondary)
                    } else {
                        Text("You need to be a group admin to create events")
                            .font(AppTypography.body2)
                            .foregroundColor(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.lg)
                .background(Color.grey50)
                .cornerRadius(AppCornerRadius.medium)
            } else {
                Picker("Select Group", selection: $viewModel.selectedGroupId) {
                    Text("Select a group").tag("")
                    ForEach(viewModel.availableGroups) { group in
                        Text(group.name).tag(group.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(AppSpacing.md)
                .background(Color.grey50)
                .cornerRadius(AppCornerRadius.medium)
            }
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var preSelectedGroupSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Group")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            if let group = preSelectedGroup {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.statusGoing)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(group.name)
                            .font(AppTypography.body1)
                            .foregroundColor(Color.appTextPrimary)
                            .fontWeight(.medium)
                        
                        Text("Event will be created for this group")
                            .font(AppTypography.body2)
                            .foregroundColor(Color.appTextSecondary)
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.lg)
                .background(Color.statusGoing.opacity(0.1))
                .cornerRadius(AppCornerRadius.medium)
            }
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Date & Time")
                .font(AppTypography.h4)
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
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text("Location")
                    .font(AppTypography.h4)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                if !viewModel.location.isEmpty {
                    Button(action: {
                        searchLocationInMaps(location: viewModel.location)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "map")
                                .font(.system(size: 14))
                            Text("Search")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color.statusAdmin)
                    }
                }
            }
            
            AppTextField(
                title: "Location",
                placeholder: "e.g., Central Park, New York or 123 Main St, City",
                text: $viewModel.location
            )
            
            Text("💡 Tip: Include city/state for better accuracy")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color.grey500)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var capacitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Capacity & Guests")
                .font(AppTypography.h4)
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
            
            AppTextField(
                title: "Additional Guests",
                placeholder: "Number of non-member guests (optional)",
                text: $viewModel.guests
            )
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Description")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextArea(
                title: "Event Description",
                placeholder: "Enter event description (optional)",
                text: $viewModel.description
            )
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Notifications")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Toggle("Notify Members via Email?", isOn: $viewModel.notifyGroupMembers)
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextPrimary)
                }
                
                if viewModel.notifyGroupMembers {
                    Text("All group members will receive an email notification about this new event.")
                        .font(AppTypography.caption)
                        .foregroundColor(Color.appTextSecondary)
                        .padding(.leading, AppSpacing.sm)
                }
            }
        }
        .padding(AppSpacing.xl)
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
