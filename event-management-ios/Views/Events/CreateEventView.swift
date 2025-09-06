import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateEventViewModel()
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    
    let preSelectedGroup: Group?
    
    init(preSelectedGroup: Group? = nil) {
        self.preSelectedGroup = preSelectedGroup
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
            if let preSelectedGroup = preSelectedGroup {
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
                
                Text("Create Event")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("Create") {
                    Task {
                        await viewModel.createEvent()
                        if viewModel.isSuccess {
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
            Text("Location")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextField(
                title: "Location",
                placeholder: "Enter event location (optional)",
                text: $viewModel.location
            )
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var capacitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Capacity")
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
