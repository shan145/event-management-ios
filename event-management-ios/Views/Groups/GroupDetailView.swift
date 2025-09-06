import SwiftUI

struct GroupDetailView: View {
    let group: Group
    @StateObject private var viewModel = GroupDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    let onGroupUpdated: (() -> Void)?
    
    init(group: Group, onGroupUpdated: (() -> Void)? = nil) {
        self.group = group
        self.onGroupUpdated = onGroupUpdated
    }
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingLeaveAlert = false
    @State private var showingInviteSheet = false
    @State private var showingGroupAdminSheet = false
    
    private var canManageGroup: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        return currentUser.isAdminOfGroup(group.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(group.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "person.3")
                            .foregroundColor(.blue)
                        Text("\(group.members?.count ?? 0) members")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description removed - Group model no longer has description field
                }
                .padding(.horizontal)
                
                Divider()
                
                // Group Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Group Statistics")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        StatCard(
                            icon: "person.2",
                            title: "Members",
                            value: "\(group.members?.count ?? 0)",
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "calendar",
                            title: "Events",
                            value: "\(group.totalEventCount)",
                            color: .green
                        )
                    }
                    
                    HStack {
                        StatCard(
                            icon: "person.crop.circle.badge.plus",
                            title: "Admins",
                            value: "\(((group.adminId != nil ? 1 : 0) + (group.groupAdmins?.count ?? 0)))",
                            color: .purple
                        )
                        
                        StatCard(
                            icon: "clock",
                            title: "Created",
                            value: group.formattedCreatedDate,
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)
                
                // Members List
                if let members = group.members, !members.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Members")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if canManageGroup {
                                Button("Manage") {
                                    showingGroupAdminSheet = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        LazyVStack(spacing: 8) {
                            ForEach(members, id: \.id) { member in
                                MemberRow(
                                    member: member,
                                    isAdmin: (group.adminId?.id == member.id) || (group.groupAdmins?.contains(where: { $0.id == member.id }) ?? false)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Events List - Removed since Group model no longer has events field
                // Events would need to be loaded separately via API call
                
                Spacer(minLength: 100)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    if canManageGroup {
                        Button("Invite") {
                            showingInviteSheet = true
                        }
                        
                        Button("Edit") {
                            showingEditSheet = true
                        }
                        
                        Button("Delete") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Leave Group") {
                            showingLeaveAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditGroupView(group: group)
        }
        .sheet(isPresented: $showingInviteSheet) {
            InviteMembersView(group: group)
        }
        .sheet(isPresented: $showingGroupAdminSheet) {
            GroupAdminView(group: group)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    // Refresh group data when admin sheet is dismissed
                    viewModel.loadGroupDetails(groupId: group.id)
                    onGroupUpdated?()
                }
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
        .alert("Leave Group", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await viewModel.leaveGroup(groupId: group.id)
                    presentationMode.wrappedValue.dismiss()
                    onGroupUpdated?()
                }
            }
        } message: {
            Text("Are you sure you want to leave \"\(group.name)\"? You will need to be re-invited to rejoin.")
        }
        .onAppear {
            viewModel.loadGroupDetails(groupId: group.id)
        }
    }
}

struct MemberRow: View {
    let member: User
    let isAdmin: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.firstName.prefix(1) + member.lastName.prefix(1))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(member.firstName) \(member.lastName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if isAdmin {
                        Text("Admin")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(4)
                    }
                }
                
                // Email removed for privacy
            }
            
            Spacer()
            
        }
        .padding(.vertical, 4)
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(event.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(event.formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupDetailView(group: Group.sampleGroup)
        }
    }
}
