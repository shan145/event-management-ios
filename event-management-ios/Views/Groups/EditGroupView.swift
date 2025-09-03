import SwiftUI

struct EditGroupView: View {
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
                
                Text("Edit Group")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Save") {
                    // TODO: Implement save functionality
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top)
            
            VStack {
                Text("Edit Group")
                    .font(.title)
                
                Text("Group: \(group.name)")
                    .padding()
                
                Text("Edit functionality coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
}

struct EditGroupView_Previews: PreviewProvider {
    static var previews: some View {
        EditGroupView(group: Group.sampleGroup)
    }
}
