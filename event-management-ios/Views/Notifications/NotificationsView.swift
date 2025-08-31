import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @State private var showingNotificationSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                if notificationService.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Notifications")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Settings") {
                        showingNotificationSettings = true
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if !notificationService.notifications.isEmpty {
                        Button("Mark All Read") {
                            Task {
                                await notificationService.markAllNotificationsAsRead()
                            }
                        }
                    }
                }
            }
            .refreshable {
                await notificationService.fetchNotifications()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .onAppear {
                Task {
                    await notificationService.fetchNotifications()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Notifications")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("You're all caught up! Check back later for updates about your events and groups.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if !notificationService.isAuthorized {
                AppButton(
                    title: "Enable Notifications",
                    action: {
                        Task {
                            await notificationService.requestAuthorization()
                        }
                    },
                    style: .primary
                )
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private var notificationsList: some View {
        List {
            ForEach(notificationService.notifications) { notification in
                NotificationRowView(notification: notification) {
                    Task {
                        await notificationService.markNotificationAsRead(notificationId: notification.id)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Notification Row View

struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Notification Icon
                Circle()
                    .fill(notificationColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: notificationIcon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                // Notification Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(notification.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if !notification.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(notification.isRead ? 0.7 : 1.0)
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .eventInvite, .eventReminder:
            return .blue
        case .eventUpdate, .eventCancelled:
            return .orange
        case .groupInvite, .groupUpdate:
            return .green
        case .attendeeJoined, .attendeeLeft, .waitlistPromoted:
            return .purple
        case .general:
            return .gray
        }
    }
    
    private var notificationIcon: String {
        switch notification.type {
        case .eventInvite, .eventReminder:
            return "calendar.badge.plus"
        case .eventUpdate, .eventCancelled:
            return "calendar.badge.exclamationmark"
        case .groupInvite, .groupUpdate:
            return "person.3"
        case .attendeeJoined, .attendeeLeft:
            return "person.badge.plus"
        case .waitlistPromoted:
            return "arrow.up.circle"
        case .general:
            return "bell"
        }
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var preferencesViewModel = PreferencesSettingsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Notification Authorization Status
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notification Settings")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: notificationService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(notificationService.isAuthorized ? .green : .red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notificationService.isAuthorized ? "Notifications Enabled" : "Notifications Disabled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(notificationService.isAuthorized ? "You'll receive notifications for important updates" : "Enable notifications to stay updated")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !notificationService.isAuthorized {
                                AppButton(
                                    title: "Enable",
                                    action: {
                                        Task {
                                            await notificationService.requestAuthorization()
                                        }
                                    },
                                    style: .primary
                                )
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Notification Preferences
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notification Preferences")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            Toggle("Event Reminders", isOn: $preferencesViewModel.eventReminders)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                            
                            Toggle("Group Updates", isOn: $preferencesViewModel.groupUpdates)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                            
                            Toggle("Email Notifications", isOn: $preferencesViewModel.emailNotifications)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                            
                            Toggle("Push Notifications", isOn: $preferencesViewModel.pushNotifications)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Save Button
                    AppButton(
                        title: "Save Settings",
                        action: {
                            Task {
                                await preferencesViewModel.savePreferences()
                                presentationMode.wrappedValue.dismiss()
                            }
                        },
                        style: .primary,
                        isLoading: preferencesViewModel.isLoading
                    )
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Notification Settings")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Notification Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                preferencesViewModel.loadPreferences()
            }
        }
    }
}

// MARK: - Preview

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
