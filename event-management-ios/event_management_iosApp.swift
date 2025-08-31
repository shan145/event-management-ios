//
//  event_management_iosApp.swift
//  event-management-ios
//
//  Created by Samuel Han on 8/30/25.
//

import SwiftUI

@main
struct event_management_iosApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .preferredColorScheme(.light) // Force light mode to match web app
        }
    }
}
