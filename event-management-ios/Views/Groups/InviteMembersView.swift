import SwiftUI

struct InviteMembersView: View {
    let group: Group
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    @State private var showingCopyAlert = false
    
    private var inviteURL: String {
        // In a real app, this would be your app's deep link or web URL
        "https://eventify.app/join/\(group.inviteToken ?? "")"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color.appPrimary)
                
                Spacer()
                
                Text("Invite Members")
                    .font(AppTypography.h4)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("Share") {
                    showingShareSheet = true
                }
                .foregroundColor(Color.appPrimary)
            }
            .padding(AppSpacing.lg)
            .background(Color.appSurface)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Group info
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Invite people to join:")
                            .font(AppTypography.h5)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appTextPrimary)
                        
                        Text(group.name)
                            .font(AppTypography.h4)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appPrimary)
                        
                        if let tags = group.tags, !tags.isEmpty {
                            Text("Tags: \(tags.joined(separator: ", "))")
                                .font(AppTypography.body2)
                                .foregroundColor(Color.appTextSecondary)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Invite link section
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Invite Link")
                            .font(AppTypography.h5)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appTextPrimary)
                        
                        VStack(spacing: AppSpacing.sm) {
                            HStack {
                                Text(inviteURL)
                                    .font(AppTypography.body2)
                                    .foregroundColor(Color.appTextSecondary)
                                    .lineLimit(nil)
                                    .textSelection(.enabled)
                                
                                Spacer()
                                
                                Button("Copy") {
                                    UIPasteboard.general.string = inviteURL
                                    showingCopyAlert = true
                                }
                                .font(AppTypography.body2)
                                .foregroundColor(Color.appPrimary)
                            }
                            .padding(AppSpacing.md)
                            .background(Color.grey100)
                            .cornerRadius(AppCornerRadius.medium)
                            
                            // Share button
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Invite Link")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(AppSpacing.md)
                                .background(Color.appPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(AppCornerRadius.medium)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("How it works:")
                            .font(AppTypography.body1)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appTextPrimary)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("1. Share the invite link with people you want to join")
                            Text("2. They can click the link to view group details")
                            Text("3. If they have the app, they can join instantly")
                            Text("4. If not, they'll be directed to download the app first")
                        }
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    Spacer(minLength: AppSpacing.lg)
                }
                .padding(.top, AppSpacing.lg)
            }
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [inviteURL])
        }
        .alert("Link Copied!", isPresented: $showingCopyAlert) {
            Button("OK") { }
        } message: {
            Text("The invite link has been copied to your clipboard.")
        }
    }
}

struct InviteMembersView_Previews: PreviewProvider {
    static var previews: some View {
        InviteMembersView(group: Group.sampleGroup)
    }
}
