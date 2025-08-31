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
        .onChange(of: authManager.errorMessage) { errorMessage in
            showErrorAlert = errorMessage != nil
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
    @State private var testResult = ""
    @State private var showTestResult = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Logo/Header
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(Color.appPrimary)
                    
                    Text("Event Management")
                        .font(AppTypography.h2)
                        .foregroundColor(Color.appTextPrimary)
                    
                    Text("Organize and manage your events with ease")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xxl)
                
                // Test Connection Button (for debugging)
                Button("Test Connection") {
                    Task {
                        do {
                            let result = try await APIService.shared.testConnection()
                            testResult = result
                            showTestResult = true
                        } catch {
                            testResult = "Error: \(error.localizedDescription)"
                            showTestResult = true
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
                
                // Auth Forms
                if isLogin {
                    LoginView()
                } else {
                    SignupView()
                }
                
                Spacer()
                
                // Toggle between login/signup
                Button(isLogin ? "Don't have an account? Sign up" : "Already have an account? Log in") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLogin.toggle()
                    }
                }
                .buttonStyle(TextButtonStyle())
                .padding(.bottom, AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.lg)
            .background(Color.appBackground)
        }
        .alert("Connection Test Result", isPresented: $showTestResult) {
            Button("OK") { }
        } message: {
            Text(testResult)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some View {
        TabView {
            // Show appropriate dashboard based on user role
            if authManager.currentUser?.isAdmin == true {
                AdminDashboardView()
                    .tabItem {
                        Image(systemName: "shield")
                        Text("Admin")
                    }
            } else {
                DashboardView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Dashboard")
                    }
            }
            
            EventsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
            
            GroupsView()
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
        }
        .onDisappear {
            // Stop real-time updates when the app becomes inactive
            notificationService.stopRealTimeUpdates()
        }
    }
    
    private var unreadNotificationCount: Int {
        notificationService.notifications.filter { !$0.isRead }.count
    }
}

// MARK: - Settings View (Legacy - keeping for reference)
// The new SettingsView is now in Views/Settings/SettingsView.swift

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
}
