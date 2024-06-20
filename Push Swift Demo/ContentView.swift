//
//  ContentView.swift
//  Push Swift Demo
//
//  Created by Ayomide Gbogboade on 11/06/2024.
//

import Push
import SwiftUI

struct ContentView: View {
    @State private var address = ""
    @State private var pushUser: PushAPI? = nil
    @State private var isLoading = false
    @FocusState private var isAmountFocused: Bool

    func initPush() async throws {
        isLoading = true
        let privateKey = "a59c37c9b61b73f824972b901e0b4ae914750fd8de94c5dfebc4934ff1d12d3c" // getRandomAccount()
        let signer = try SignerPrivateKey(privateKey: privateKey)
        address = try await signer.getAddress()
        pushUser = try await Push.PushAPI.initializePush(signer: signer, options: Push.PushAPI.PushAPIInitializeOptions(env: .STAGING))

        try await loadChats()
    }

    func disconnectWallet() async throws {
        pushUser = nil
        chats.removeAll()
        requests.removeAll()
    }

    @State private var chats: [Push.PushChat.Feeds] = []
    @State private var requests: [Push.PushChat.Feeds] = []
    @State private var selection = 0
    func loadChats() async throws {
        isLoading = true

        chats = try await pushUser?.chat.list(type: .CHAT) ?? []
        requests = try await pushUser?.chat.list(type: .REQUESTS) ?? []

        isLoading = false
    }

    var body: some View {
        NavigationStack {
            if address.isEmpty {
                Form {
                    Text("No Wallet connected")
                }
                .navigationTitle("Push Swift")
                .toolbar {
                    if isLoading {
                        ProgressView()

                    } else {
                        Button(action: {
                            Task {
                                try await initPush()
                            }

                        }) {
                            Text("Connect wallet")
                        }
                    }
                }

            } else {
                Text(address).font(.system(size: 12)).lineLimit(2).padding()
                TabView(selection: $selection) {
                    chatList
                        .tabItem { Text("CHAT").font(.caption) }.tag(0)
                    requestsList
                        .tabItem { Text("REQUESTS").font(.caption) }.tag(1)
                }
                .navigationTitle("Push Swift")
                .toolbar {
                    HStack {
                        if isLoading {
                            ProgressView()
                        }

                        Button(action: {
                            Task {
                                try await disconnectWallet()
                            }

                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
        }
    }

    var chatList: some View {
        return Form {
            Section(header: Text("Chats")) {
                if isLoading && chats.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Loading").padding()
                    }
                }
                List(chats, id: \.chatId) { chat in
                    NavigationLink {
                      ChatView(feed: chat, pushUser: pushUser!)
                    } label: {
                        ChatTile(chat: chat)
                    }
                }
            }
        }
    }

    var requestsList: some View {
        Form {
            Section(header: Text("Requests")) {
                if isLoading && requests.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Loading").padding()
                    }
                }
                List(requests, id: \.chatId) {
                    chat in RequestTile(
                        chat: chat,
                        onAccept: {
                            chatId in

                            let result = try await pushUser!.chat.accept(target: chatId)
                            try await loadChats()
                            return result != nil
                        }
                    )
                }
            }
        }
    }
}

struct Base64ImageView: View {
    var base64String: String

    var body: some View {
        if let imageData = Data(base64Encoded: base64String),
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            Text("Failed to load image")
        }
    }
}

struct ChatTile: View {
    let chat: Push.PushChat.Feeds

    var body: some View {
        HStack {
            if chat.profilePicture != nil {
                Base64ImageView(base64String: (chat.groupInformation != nil) ? chat.groupInformation!.groupImage!.replacingOccurrences(of: "data:image/png;base64,", with: "") : chat.profilePicture!.replacingOccurrences(of: "data:image/png;base64,", with: "")
                )
                .frame(width: 40, height: 40)
            } else {
                Image(systemName: "lock").frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, content: {
                Text(chat.groupInformation?.groupName ?? chat.name ?? chat.chatId ?? "no chat id").font(.system(size: 12)).lineLimit(1)
                Text(chat.msg?.messageObj?.content ?? "Send first message").font(.system(size: 15)).lineLimit(2).fontWeight(.semibold)
            })
        }
    }
}

struct RequestTile: View {
    let chat: Push.PushChat.Feeds
    let onAccept: (String) async throws -> Bool

    @State private var isLoading = false
    var body: some View {
        HStack {
            if chat.profilePicture != nil {
                Base64ImageView(base64String: (chat.groupInformation != nil) ? chat.groupInformation!.groupImage!.replacingOccurrences(of: "data:image/png;base64,", with: "") : chat.profilePicture!.replacingOccurrences(of: "data:image/png;base64,", with: "")
                )
                .frame(width: 40, height: 40)
            } else {
                Image(systemName: "lock").frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, content: {
                Text(chat.groupInformation?.groupName ?? chat.chatId ?? "no chat id")
                    .font(.system(size: 12)).lineLimit(1)
                Text("Accept invite to see messages")
                    .font(.system(size: 10)).lineLimit(2).fontWeight(.semibold)
            })
            Spacer()
            if isLoading {
                ProgressView()
            } else {
                Button("Accept", action: {
                    Task {
                        isLoading = true
                        let _ = try await onAccept(chat.chatId!)
                        isLoading = false
                    }
                })
            }
        }
    }
}

#Preview {
    ContentView()
}
