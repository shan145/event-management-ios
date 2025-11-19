import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @State private var showingNotificationSettings = false
    
    var body: some View {
        NavigationView {
            List {
                // Header Section
                Section {
                    HStack {
                        Text("Notifications")
                            .font(AppTypography.h4)
                            .foregroundColor(Color.appTextPrimary)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                showingNotificationSettings = true
                            }) {
                                Text("Settings")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if !notificationService.notifications.isEmpty {
                                Menu {
                                    Button(action: {
                                        Task {
                                            await notificationService.markAllNotificationsAsRead()
                                        }
                                    }) {
                                        Label("Mark All Read", systemImage: "checkmark.circle")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        Task {
                                            await notificationService.clearAllNotifications()
                                        }
                                    }) {
                                        Label("Clear All", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                
                // Notifications List
                if notificationService.notifications.isEmpty {
                    Section {
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        ForEach(notificationService.notifications) { notification in
                            NotificationRowView(notification: notification) {
                                Task {
                                    await notificationService.markNotificationAsRead(notificationId: notification.id)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    } footer: {
                        if notificationService.unreadCount > 0 {
                            Text("\(notificationService.unreadCount) unread")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .background(Color.appBackground)
            .refreshable {
                await notificationService.fetchNotifications()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                Task {
                    await notificationService.fetchNotifications()
                }
            }
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
            case .eventInvite, .eventReminder, .eventCreated:
                return .blue
            case .eventUpdate, .eventUpdated, .eventCancelled:
                return .orange
            case .groupInvite, .groupUpdate, .newMemberJoined, .memberRemoved, .groupMessage:
                return .green
            case .attendeeJoined, .attendeeLeft, .waitlistPromoted, .attendeeStatusChanged:
                return .purple
            case .groupAdminAssigned:
                return .indigo
            case .systemAnnouncement:
                return .red
            case .passwordReset, .welcome:
                return .cyan
            case .general:
                return .gray
            }
        }
        
        private var notificationIcon: String {
            switch notification.type {
            case .eventInvite, .eventReminder, .eventCreated:
                return "calendar.badge.plus"
            case .eventUpdate, .eventUpdated, .eventCancelled:
                return "calendar.badge.exclamationmark"
            case .groupInvite, .groupUpdate, .groupMessage:
                return "person.3"
            case .newMemberJoined, .attendeeJoined:
                return "person.badge.plus"
            case .memberRemoved, .attendeeLeft:
                return "person.badge.minus"
            case .waitlistPromoted, .attendeeStatusChanged:
                return "arrow.up.circle"
            case .groupAdminAssigned:
                return "star.circle"
            case .systemAnnouncement:
                return "megaphone"
            case .passwordReset:
                return "key"
            case .welcome:
                return "hand.wave"
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
                    VStack(spacing: AppSpacing.xl) {
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
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Notification Preferences")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            EmailPreferenceSection(
                                isOn: $preferencesViewModel.emailNotificationsEnabled,
                                isLoading: preferencesViewModel.isLoading
                            )
                            
                            NotificationPreferenceSection(
                                title: "Push Notifications",
                                rows: [
                                    NotificationPreferenceRow(title: "Event Invites", binding: $preferencesViewModel.pushEventInvites),
                                    NotificationPreferenceRow(title: "Event Reminders", binding: $preferencesViewModel.pushEventReminders),
                                    NotificationPreferenceRow(title: "Event Updates", binding: $preferencesViewModel.pushEventUpdates),
                                    NotificationPreferenceRow(title: "Event Cancellations", binding: $preferencesViewModel.pushEventCancellations),
                                    NotificationPreferenceRow(title: "Group Invites", binding: $preferencesViewModel.pushGroupInvites),
                                    NotificationPreferenceRow(title: "Group Updates", binding: $preferencesViewModel.pushGroupUpdates),
                                    NotificationPreferenceRow(title: "System Announcements", binding: $preferencesViewModel.pushSystemAnnouncements)
                                ],
                                isLoading: preferencesViewModel.isLoading
                            )
                            
                            if let errorMessage = preferencesViewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if preferencesViewModel.showSuccess {
                                Text("Preferences updated successfully")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Save Button
                        AppButton(
                            title: "Save Settings",
                            action: {
                                Task {
                                    await preferencesViewModel.savePreferences()
                                }
                            },
                            style: .primary,
                            isLoading: preferencesViewModel.isLoading
                        )
                        .padding(.top, AppSpacing.md)
                        .disabled(preferencesViewModel.isLoading)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.xl)
                }
                .navigationTitle("Notification Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Done")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.appPrimary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .onAppear {
                Task {
                    await preferencesViewModel.loadPreferences()
                }
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        hideKeyboard()
                    }
            )
        }
        
        private func hideKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - Preview
    
    struct NotificationsView_Previews: PreviewProvider {
        static var previews: some View {
            NotificationsView()
        }
    }
    
    struct NotificationPreferenceSection: View {
        let title: String
        let rows: [NotificationPreferenceRow]
        let isLoading: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 0) {
                    ForEach(rows.indices, id: \.self) { index in
                        HStack {
                            Text(rows[index].title)
                                .font(.body)
                            Spacer()
                            Toggle("", isOn: rows[index].binding)
                                .labelsHidden()
                                .disabled(isLoading)
                        }
                        .padding(.vertical, 8)
                        
                        if index < rows.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }
    
    struct EmailPreferenceSection: View {
        @Binding var isOn: Bool
        let isLoading: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Email Notifications")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Receive All Email Notifications")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text("Includes event invites, reminders, updates, cancellations, group invites/updates, and system announcements.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isOn)
                            .labelsHidden()
                            .disabled(isLoading)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }
    
    struct NotificationPreferenceRow {
        let title: String
        let binding: Binding<Bool>
    }
}
