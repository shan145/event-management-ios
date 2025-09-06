//
//  EventifyApp.swift
//  Eventify
//
//  Created by Samuel Han on 8/30/25.
//

import SwiftUI

@main
struct EventifyApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .preferredColorScheme(.light) // Force light mode to match web app
        }
    }
}
