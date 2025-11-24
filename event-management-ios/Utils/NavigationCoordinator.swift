import Foundation
import SwiftUI

@MainActor
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var pendingInviteToken: String?
    @Published var shouldShowInviteView = false
    
    private init() {}
    
    func handleDeepLink(_ url: URL) {
        print("🔗 NavigationCoordinator: handleDeepLink called with URL: \(url.absoluteString)")
        print("🔗 NavigationCoordinator: URL host: \(url.host ?? "nil")")
        print("🔗 NavigationCoordinator: URL pathComponents: \(url.pathComponents)")
        
        guard let host = url.host, host == "us-eventify.com" else {
            print("❌ NavigationCoordinator: Host mismatch. Expected 'us-eventify.com', got: \(url.host)")
            return
        }
        
        let pathComponents = url.pathComponents
        
        // pathComponents[0] is "/", pathComponents[1] is "join", pathComponents[2] is the token
        if pathComponents.count >= 3 && pathComponents[1] == "join" {
            let token = pathComponents[2]
            print("🔗 NavigationCoordinator: Extracted token: \(token)")
            if !token.isEmpty {
                pendingInviteToken = token
                shouldShowInviteView = true
                print("✅ NavigationCoordinator: Set pendingInviteToken and shouldShowInviteView = true")
            } else {
                print("❌ NavigationCoordinator: Token is empty")
            }
        } else {
            print("❌ NavigationCoordinator: Path doesn't match. Count: \(pathComponents.count), pathComponents[1]: \(pathComponents.count > 1 ? pathComponents[1] : "N/A")")
        }
    }
    
    func clearPendingInvite() {
        pendingInviteToken = nil
        shouldShowInviteView = false
    }
}

