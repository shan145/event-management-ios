import SwiftUI

struct TextExpansionModal: View {
    let title: String
    let text: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text(text)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appPrimary)
                }
            }
        }
    }
}

struct ExpandableText: View {
    let text: String
    let lineLimit: Int
    let font: Font
    let color: Color
    let title: String
    
    @State private var isExpanded = false
    @State private var showingModal = false
    
    init(
        _ text: String,
        lineLimit: Int = 2,
        font: Font = .system(size: 15, weight: .regular, design: .rounded),
        color: Color = Color.grey600,
        title: String = "Full Text"
    ) {
        self.text = text
        self.lineLimit = lineLimit
        self.font = font
        self.color = color
        self.title = title
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(text)
                .font(font)
                .foregroundColor(color)
                .lineLimit(isExpanded ? nil : lineLimit)
                .multilineTextAlignment(.leading)
                .onTapGesture {
                    if isTextTruncated() {
                        showingModal = true
                    }
                }
            
            if isTextTruncated() && !isExpanded {
                Button(action: {
                    showingModal = true
                }) {
                    Text("Read more")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.appPrimary)
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showingModal) {
            TextExpansionModal(
                title: title,
                text: text,
                isPresented: $showingModal
            )
        }
    }
    
    private func isTextTruncated() -> Bool {
        let textSize = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 15)])
        let lineHeight = UIFont.systemFont(ofSize: 15).lineHeight
        let maxHeight = lineHeight * CGFloat(lineLimit)
        
        return textSize.height > maxHeight
    }
}

#Preview {
    VStack(spacing: 20) {
        ExpandableText(
            "This is a short text that should not be truncated.",
            lineLimit: 2,
            title: "Short Text"
        )
        
        ExpandableText(
            "This is a much longer text that will definitely be truncated because it contains many words and sentences that exceed the line limit. This text should show a 'Read more' button and allow the user to tap to see the full content in a modal.",
            lineLimit: 2,
            title: "Long Text"
        )
    }
    .padding()
}
