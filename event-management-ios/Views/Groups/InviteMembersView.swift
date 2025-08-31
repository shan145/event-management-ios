import SwiftUI

struct InviteMembersView: View {
    let group: Group
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Invite Members")
                    .font(.title)
                
                Text("Group: \(group.name)")
                    .padding()
                
                Text("Invite functionality coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Invite Members")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        // TODO: Implement invite functionality
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct InviteMembersView_Previews: PreviewProvider {
    static var previews: some View {
        InviteMembersView(group: Group.sampleGroup)
    }
}
