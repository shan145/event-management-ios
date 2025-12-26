import SwiftUI

struct EventChatView: View {
    let eventId: String
    @StateObject private var viewModel = EventChatViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            messagesList
            
            Divider()
            
            messageInput
        }
        .navigationTitle("Event Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startPolling(eventId: eventId)
            Task {
                await viewModel.markMessagesAsRead(eventId: eventId)
            }
        }
        .onDisappear {
            viewModel.stopPolling()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No messages yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Start the conversation!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    }
                    
                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            currentUserId: authManager.currentUser?.id
                        )
                            .id(message.id)
                    }
                    
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView()
                            .padding()
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var messageInput: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        messageText = ""
        isInputFocused = false
        
        Task {
            await viewModel.sendMessage(eventId: eventId, content: content)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let currentUserId: String?
    
    private var isFromCurrentUser: Bool {
        message.isFromCurrentUser(currentUserId: currentUserId)
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isFromCurrentUser {
                    Text(message.senderId.fullName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

@MainActor
class EventChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var pollingTask: Task<Void, Never>?
    private var lastMessageId: String?
    
    func startPolling(eventId: String) {
        stopPolling()
        
        Task {
            await loadMessages(eventId: eventId)
        }
        
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                
                if !Task.isCancelled {
                    await loadMessages(eventId: eventId, incremental: true)
                }
            }
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    func loadMessages(eventId: String, incremental: Bool = false) async {
        do {
            var since: String? = nil
            if incremental {
                if let lastMessage = messages.last {
                    since = lastMessage.createdAt
                }
            }
            
            let response = try await apiService.getMessages(eventId: eventId, limit: 50, before: nil, since: since)
            
            if incremental {
                let existingIds = Set(messages.map { $0.id })
                let newMessages = response.data.messages.filter { !existingIds.contains($0.id) }
                
                if !newMessages.isEmpty {
                    messages.append(contentsOf: newMessages)
                    messages.sort { msg1, msg2 in
                        let date1 = ISO8601DateFormatter().date(from: msg1.createdAt) ?? Date.distantPast
                        let date2 = ISO8601DateFormatter().date(from: msg2.createdAt) ?? Date.distantPast
                        return date1 < date2
                    }
                    lastMessageId = messages.last?.id
                }
            } else {
                messages = response.data.messages
                lastMessageId = messages.last?.id
            }
        } catch {
            if !incremental {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    func sendMessage(eventId: String, content: String) async {
        isSending = true
        errorMessage = nil
        
        do {
            let response = try await apiService.sendMessage(eventId: eventId, content: content)
            
            if !messages.contains(where: { $0.id == response.data.message.id }) {
                messages.append(response.data.message)
                messages.sort { msg1, msg2 in
                    let date1 = ISO8601DateFormatter().date(from: msg1.createdAt) ?? Date.distantPast
                    let date2 = ISO8601DateFormatter().date(from: msg2.createdAt) ?? Date.distantPast
                    return date1 < date2
                }
                lastMessageId = messages.last?.id
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isSending = false
    }
    
    func markMessagesAsRead(eventId: String) async {
        do {
            _ = try await apiService.markMessagesAsRead(eventId: eventId)
        } catch {
            print("⚠️ Failed to mark messages as read: \(error)")
            // Don't show error to user, this is a background operation
        }
    }
}

