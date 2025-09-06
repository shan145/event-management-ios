//
//  ContentView.swift
//  event-management-ios
//
//  Created by Samuel Han on 8/30/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showErrorAlert = false
    
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
            GroupsView()
                .environmentObject(dashboardViewModel)
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Groups")
                }
            
            EventsView()
                .environmentObject(dashboardViewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
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
            
            // Load initial notifications
            Task {
                await notificationService.fetchNotifications()
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
