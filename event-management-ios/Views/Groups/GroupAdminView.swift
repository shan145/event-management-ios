import SwiftUI

struct GroupAdminView: View {
    let group: Group
    @StateObject private var viewModel = GroupAdminViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingInviteSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            VStack(spacing: 16) {
                HStack {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Group Admin")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Invite") {
                        showingInviteSheet = true
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // Header with group info
                headerSection
            }
            
            // Members view (no tabs needed)
            GroupMembersView(group: group, viewModel: viewModel)
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
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                viewModel.showSuccess = false
            }
        } message: {
            Text("Operation completed successfully")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
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
                
                Text("\(viewModel.members.count) members")
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
    @State private var showingMakeAdminAlert = false
    @State private var showingRemoveAdminAlert = false
    @State private var showingAddMemberSheet = false
    @State private var selectedMember: User?
    @State private var memberAction: MemberAction = .remove
    
    enum MemberAction {
        case remove, makeAdmin, removeAdmin
    }
    
    var body: some View {
        List {
            // Add Member Section
            Section(header: Text("Add Member")) {
                Button("Add Member by Email") {
                    showingAddMemberSheet = true
                }
                .foregroundColor(.blue)
            }
            
            Section(header: Text("Admins")) {
                ForEach(viewModel.admins, id: \.id) { admin in
                    MemberRowView(
                        member: admin,
                        isAdmin: true,
                        canRemove: admin.id != AuthManager.shared.currentUser?.id,
                        canMakeAdmin: false,
                        canRemoveAdmin: admin.id != AuthManager.shared.currentUser?.id && admin.id != group.adminId?.id
                    ) { action in
                        selectedMember = admin
                        memberAction = action
                        switch action {
                        case .remove:
                            showingRemoveAlert = true
                        case .removeAdmin:
                            showingRemoveAdminAlert = true
                        default:
                            break
                        }
                    }
                }
            }
            
            Section(header: Text("Members")) {
                ForEach(viewModel.members, id: \.id) { member in
                    MemberRowView(
                        member: member,
                        isAdmin: false,
                        canRemove: true,
                        canMakeAdmin: true,
                        canRemoveAdmin: false
                    ) { action in
                        selectedMember = member
                        memberAction = action
                        switch action {
                        case .remove:
                            showingRemoveAlert = true
                        case .makeAdmin:
                            showingMakeAdminAlert = true
                        default:
                            break
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .sheet(isPresented: $showingAddMemberSheet) {
            AddMemberByEmailView(group: group, viewModel: viewModel)
        }
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
        .alert("Make Admin", isPresented: $showingMakeAdminAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Make Admin") {
                if let member = selectedMember {
                    Task {
                        await viewModel.makeUserAdmin(userId: member.id, groupId: group.id)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to make this user a group admin?")
        }
        .alert("Remove Admin", isPresented: $showingRemoveAdminAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove Admin", role: .destructive) {
                if let member = selectedMember {
                    Task {
                        await viewModel.removeUserAdmin(userId: member.id, groupId: group.id)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to remove admin privileges from this user?")
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
                    .onChange(of: viewModel.allowMemberInvites) {
                        Task {
                            await viewModel.updateGroupSettings(groupId: group.id)
                        }
                    }
                
                Toggle("Require Admin Approval", isOn: $viewModel.requireAdminApproval)
                    .onChange(of: viewModel.requireAdminApproval) {
                        Task {
                            await viewModel.updateGroupSettings(groupId: group.id)
                        }
                    }
                
                Toggle("Public Group", isOn: $viewModel.isPublicGroup)
                    .onChange(of: viewModel.isPublicGroup) {
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
    let canMakeAdmin: Bool
    let canRemoveAdmin: Bool
    let onAction: (GroupMembersView.MemberAction) -> Void
    
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
                
                // Hide email for privacy as requested
                // Text(member.email)
                //     .font(.caption)
                //     .foregroundColor(.secondary)
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
            
            // Action buttons
            if canMakeAdmin || canRemove || canRemoveAdmin {
                Menu {
                    if canMakeAdmin {
                        Button("Make Admin") {
                            onAction(.makeAdmin)
                        }
                    }
                    
                    if canRemoveAdmin {
                        Button("Remove Admin") {
                            onAction(.removeAdmin)
                        }
                    }
                    
                    if canRemove {
                        Button("Remove from Group") {
                            onAction(.remove)
                        }
                        .foregroundColor(.red)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
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

// MARK: - Add Member by Email View

struct AddMemberByEmailView: View {
    let group: Group
    @ObservedObject var viewModel: GroupAdminViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("Add Member")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add") {
                    Task {
                        await addMember()
                    }
                }
                .foregroundColor(.blue)
                .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding()
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add member to \"\(group.name)\"")
                        .font(.headline)
                    
                    Text("Enter the email address of the user you want to add to this group.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email Address")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("user@example.com", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(isLoading)
                }
                
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Adding member...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color.white)
        .onAppear {
            // Clear any previous errors when the view appears
            viewModel.errorMessage = nil
        }
    }
    
    private func addMember() async {
        isLoading = true
        // Clear any previous error
        viewModel.errorMessage = nil
        
        await viewModel.addMemberByEmail(email: email, groupId: group.id)
        
        if viewModel.errorMessage == nil {
            // Success - dismiss the sheet
            presentationMode.wrappedValue.dismiss()
        }
        isLoading = false
    }
}

// MARK: - Preview

struct GroupAdminView_Previews: PreviewProvider {
    static var previews: some View {
        GroupAdminView(group: Group.sampleGroup)
    }
}
