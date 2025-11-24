import Foundation
import SwiftUI

@MainActor
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var pendingInviteToken: String?
    @Published var shouldShowInviteView = false
    
    private init() {}
    
    func handleDeepLink(_ url: URL) {
        guard let host = url.host, host == "us-eventify.com" else {
            return
        }
        
        let pathComponents = url.pathComponents
        
        if pathComponents.count >= 2 && pathComponents[1] == "join" {
            let token = pathComponents.count >= 3 ? pathComponents[2] : ""
            if !token.isEmpty {
                pendingInviteToken = token
                shouldShowInviteView = true
            }
        }
    }
    
    func clearPendingInvite() {
        pendingInviteToken = nil
        shouldShowInviteView = false
    }
}

