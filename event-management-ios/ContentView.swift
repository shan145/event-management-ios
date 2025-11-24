//
//  ContentView.swift
//  event-management-ios
//
//  Created by Samuel Han on 8/30/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var showErrorAlert = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            if authManager.isLoading {
                LoadingView()
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .sheet(isPresented: $navigationCoordinator.shouldShowInviteView) {
            if let inviteToken = navigationCoordinator.pendingInviteToken {
                InviteLinkView(inviteToken: inviteToken)
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            print("📱 ContentView: onAppear - shouldShowInviteView: \(navigationCoordinator.shouldShowInviteView), pendingToken: \(navigationCoordinator.pendingInviteToken ?? "nil")")
            // If there's a pending invite token but the sheet isn't showing, trigger it
            if let token = navigationCoordinator.pendingInviteToken, !navigationCoordinator.shouldShowInviteView {
                print("📱 ContentView: Found pending invite token, triggering sheet")
                navigationCoordinator.shouldShowInviteView = true
            }
        }
        .onChange(of: navigationCoordinator.shouldShowInviteView) { oldValue, newValue in
            print("📱 ContentView: shouldShowInviteView changed from \(oldValue) to \(newValue)")
            if newValue && navigationCoordinator.pendingInviteToken != nil {
                print("📱 ContentView: Sheet should be showing now")
            }
        }
        .onChange(of: navigationCoordinator.pendingInviteToken) { oldValue, newValue in
            print("📱 ContentView: pendingInviteToken changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
            if let token = newValue, !navigationCoordinator.shouldShowInviteView {
                print("📱 ContentView: Found new invite token, triggering sheet")
                navigationCoordinator.shouldShowInviteView = true
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("📱 ContentView: Scene phase changed from \(oldPhase) to \(newPhase)")
            if newPhase == .active {
                print("📱 ContentView: App became active - checking for pending invites")
                // When app becomes active, check for pending invites
                if let token = navigationCoordinator.pendingInviteToken {
                    print("📱 ContentView: Found pending invite token: \(token), shouldShowInviteView: \(navigationCoordinator.shouldShowInviteView)")
                    if !navigationCoordinator.shouldShowInviteView {
                        print("📱 ContentView: Triggering sheet for pending invite")
                        navigationCoordinator.shouldShowInviteView = true
                    }
                } else {
                    print("📱 ContentView: No pending invite token found")
                }
                
                // Refresh notifications and update badge when app becomes active
                if authManager.isAuthenticated {
                    Task {
                        await NotificationService.shared.fetchNotifications()
                    }
                }
            }
        }
        .onOpenURL { url in
            print("🔗 ContentView: onOpenURL called with: \(url.absoluteString)")
            Task { @MainActor in
                NavigationCoordinator.shared.handleDeepLink(url)
            }
        }
        .onChange(of: authManager.errorMessage) { _, errorMessage in
            showErrorAlert = (errorMessage != nil)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                authManager.clearError()
            }
        } message: {
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

struct AuthenticationView: View {
    @State private var isLogin = true
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Auth Forms
            if isLogin {
                LoginView()
            } else {
                SignupView()
            }
            
            Spacer()
            
            // Toggle between login/signup
            VStack(spacing: AppSpacing.sm) {
                Divider()
                    .background(Color.appTextSecondary.opacity(0.3))
                
                Button(isLogin ? "Don't have an account? Sign up" : "Already have an account? Log in") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLogin.toggle()
                    }
                }
                .buttonStyle(TextButtonStyle())
                .font(AppTypography.body2)
                .fontWeight(.medium)
                .foregroundColor(Color.appPrimary)
                .padding(.vertical, AppSpacing.sm)
                .contentShape(Rectangle())
            }
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(Color.appBackground)
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var dashboardViewModel = DashboardViewModel()
    
    var body: some View {
        TabView {
            EventsView()
                .environmentObject(dashboardViewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
            
            GroupsView()
                .environmentObject(dashboardViewModel)
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Groups")
                }
            
            NotificationsView()
                .tabItem {
                    Image(systemName: "bell")
                    Text("Notifications")
                }
                .badge(unreadNotificationCount)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(Color.appPrimary)
        .onAppear {
            // Start real-time updates when the app becomes active
            notificationService.startRealTimeUpdates()
            
            // Load initial notifications and update badge
            Task {
                await notificationService.fetchNotifications()
                // Badge will be updated automatically by updateUnreadCount()
            }
        }
        .onDisappear {
            // Stop real-time updates when the app becomes inactive
            notificationService.stopRealTimeUpdates()
        }
    }
    
    private var unreadNotificationCount: Int {
        notificationService.unreadCount
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
}
