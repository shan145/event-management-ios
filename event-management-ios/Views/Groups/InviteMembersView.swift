import SwiftUI

struct InviteMembersView: View {
    let group: Group
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Custom Header
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("Invite Members")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Invite") {
                    // TODO: Implement invite functionality
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top)
            
            VStack {
                Text("Invite Members")
                    .font(.title)
                
                Text("Group: \(group.name)")
                    .padding()
                
                Text("Invite functionality coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
}

struct InviteMembersView_Previews: PreviewProvider {
    static var previews: some View {
        InviteMembersView(group: Group.sampleGroup)
    }
}
