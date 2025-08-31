import SwiftUI

struct GroupAdminView: View {
    let group: Group
    @StateObject private var viewModel = GroupAdminViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    @State private var showingInviteSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with group info
                headerSection
                
                            // Tab picker
            HStack {
                Button("Members") {
                    selectedTab = 0
                }
                .foregroundColor(selectedTab == 0 ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == 0 ? Color.blue : Color.clear)
                .cornerRadius(8)
                
                Button("Invites") {
                    selectedTab = 1
                }
                .foregroundColor(selectedTab == 1 ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == 1 ? Color.blue : Color.clear)
                .cornerRadius(8)
                
                Button("Settings") {
                    selectedTab = 2
                }
                .foregroundColor(selectedTab == 2 ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == 2 ? Color.blue : Color.clear)
                .cornerRadius(8)
            }
            .padding()
                
                // Tab content
                if selectedTab == 0 {
                    GroupMembersView(group: group, viewModel: viewModel)
                } else if selectedTab == 1 {
                    GroupInvitesView(group: group, viewModel: viewModel)
                } else if selectedTab == 2 {
                    GroupSettingsView(group: group, viewModel: viewModel)
                }
            }
            .navigationTitle("Group Admin")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Group Admin")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Invite") {
                        showingInviteSheet = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteMembersView(group: group)
            }
            .alert("Delete Group", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteGroup(groupId: group.id)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this group? This action cannot be undone.")
            }
            .onAppear {
                Task {
                    await viewModel.loadGroupData(groupId: group.id)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Group avatar
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(group.name.prefix(1))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Group info
            VStack(spacing: 4) {
                Text(group.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(viewModel.members.count) members • \(viewModel.pendingInvites.count) pending invites")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
    }
}

// MARK: - Group Members View

struct GroupMembersView: View {
    let group: Group
    @ObservedObject var viewModel: GroupAdminViewModel
    @State private var showingRemoveAlert = false
    @State private var selectedMember: User?
    
    var body: some View {
        List {
            Section(header: Text("Admins")) {
                ForEach(viewModel.admins, id: \.id) { admin in
                    MemberRowView(
                        member: admin,
                        isAdmin: true,
                        canRemove: admin.id != AuthManager.shared.currentUser?.id
                    ) {
                        selectedMember = admin
                        showingRemoveAlert = true
                    }
                }
            }
            
            Section(header: Text("Members")) {
                ForEach(viewModel.members, id: \.id) { member in
                    MemberRowView(
                        member: member,
                        isAdmin: false,
                        canRemove: true
                    ) {
                        selectedMember = member
                        showingRemoveAlert = true
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .alert("Remove Member", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let member = selectedMember {
                    Task {
                        await viewModel.removeMember(userId: member.id, groupId: group.id)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to remove this member from the group?")
        }
    }
}

// MARK: - Group Invites View

struct GroupInvitesView: View {
    let group: Group
    @ObservedObject var viewModel: GroupAdminViewModel
    @State private var showingRevokeAlert = false
    @State private var selectedInvite: GroupInvite?
    
    var body: some View {
        List {
            if viewModel.pendingInvites.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("No Pending Invites")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("All invites have been accepted or expired.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                Section(header: Text("Pending Invites")) {
                    ForEach(viewModel.pendingInvites, id: \.id) { invite in
                        InviteRowView(invite: invite) {
                            selectedInvite = invite
                            showingRevokeAlert = true
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .alert("Revoke Invite", isPresented: $showingRevokeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Revoke", role: .destructive) {
                if let invite = selectedInvite {
                    Task {
                        await viewModel.revokeInvite(inviteId: invite.id, groupId: group.id)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to revoke this invite?")
        }
    }
}

// MARK: - Group Settings View

struct GroupSettingsView: View {
    let group: Group
    @ObservedObject var viewModel: GroupAdminViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            Section(header: Text("Group Information")) {
                HStack {
                    Text("Group Name")
                    Spacer()
                    Text(group.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Created")
                    Spacer()
                    Text(group.formattedCreatedDate)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total Members")
                    Spacer()
                    Text("\(viewModel.members.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Group Settings")) {
                Toggle("Allow Member Invites", isOn: $viewModel.allowMemberInvites)
                    .onChange(of: viewModel.allowMemberInvites) { newValue in
                        Task {
                            await viewModel.updateGroupSettings(groupId: group.id)
                        }
                    }
                
                Toggle("Require Admin Approval", isOn: $viewModel.requireAdminApproval)
                    .onChange(of: viewModel.requireAdminApproval) { newValue in
                        Task {
                            await viewModel.updateGroupSettings(groupId: group.id)
                        }
                    }
                
                Toggle("Public Group", isOn: $viewModel.isPublicGroup)
                    .onChange(of: viewModel.isPublicGroup) { newValue in
                        Task {
                            await viewModel.updateGroupSettings(groupId: group.id)
                        }
                    }
            }
            
            Section(header: Text("Danger Zone")) {
                Button("Delete Group") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .listStyle(PlainListStyle())
        .alert("Delete Group", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteGroup(groupId: group.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this group? This action cannot be undone and will remove all members and events.")
        }
    }
}

// MARK: - Supporting Views

struct MemberRowView: View {
    let member: User
    let isAdmin: Bool
    let canRemove: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.firstName.prefix(1) + member.lastName.prefix(1))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            // Member info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(member.firstName) \(member.lastName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Admin badge
            if isAdmin {
                Text("Admin")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            // Remove button
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "person.fill.xmark")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct InviteRowView: View {
    let invite: GroupInvite
    let onRevoke: () -> Void
    
    var body: some View {
        HStack {
            // Invite icon
            Circle()
                .fill(Color.orange)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "envelope")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                )
            
            // Invite info
            VStack(alignment: .leading, spacing: 2) {
                Text(invite.email)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Invited \(invite.formattedInvitedDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Revoke button
            Button(action: onRevoke) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct GroupAdminView_Previews: PreviewProvider {
    static var previews: some View {
        GroupAdminView(group: Group.sampleGroup)
    }
}
