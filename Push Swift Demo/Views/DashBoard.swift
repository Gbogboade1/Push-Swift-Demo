import Push
import SwiftUI

// #Preview {
//    DashBoard()
// }

struct DashBoard: View {
    @State private var address = ""
    @State private var pushUser: PushAPI? = nil
    @State private var pushStream: PushStream? = nil
    @State private var isLoading = false
    @FocusState private var isAmountFocused: Bool
    @State private var path = NavigationPath()

    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    func initPush() async throws {
        isLoading = true
        let privateKey = "a59c37c9b61b73f824972b901e0b4ae914750fd8de94c5dfebc4934ff1d12d3c" // getRandomAccount()
        let signer = try SignerPrivateKey(privateKey: privateKey)
        address = try await signer.getAddress()
        pushUser = try await Push.PushAPI.initializePush(signer: signer, options: Push.PushAPI.PushAPIInitializeOptions(env: .STAGING))
        pushStream = try await pushUser!.initStream(
            listen: [.CHAT, .CHAT_OPS, .CONNECT, .DISCONNECT],
            options: PushStreamInitializeOptions(
                filter: PushStreamFilter(
                    channels: ["*"],
                    chats: ["*"],
                    space: ["*"]
                )
            ))

        pushStream?.on(STREAM.CHAT.rawValue, listener: { it in
            print("Scocket CHAT: \(it)")
            Task {
                try await loadChats()
            }

        })

        pushStream?.on(STREAM.CHAT_OPS.rawValue, listener: { it in
            print("Scocket CHAT_OPS: \(it)")
            Task {
                try await loadChats()
            }

        })

        try await loadChats()

        try await pushStream?.connect()
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

    @State private var isShowingCreateGroup = false

    var body: some View {
        if address.isEmpty {
            NavigationStack {
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
            }

        } else {
            NavigationView {
                VStack {
                    Text(address).font(.system(size: 12)).lineLimit(2).padding()
                    TabView(selection: $selection) {
                        chatList
                            .tabItem {
                                Text("CHAT").font(.title)
                            }.tag(0)
                        requestsList
                            .tabItem {
                                Text("REQUESTS")
                                    .font(.title)
                            }.tag(1)
                    }
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
            Section(header: HStack {
                Text("Chats")
                Spacer()
                if pushUser != nil {
                    NavigationLink(
                        destination: CreateGroup(
                            pushUser: pushUser!,
                            onClose: {
                                self.isShowingCreateGroup = false
                            }
                        ),

                        isActive: $isShowingCreateGroup

                    ) {
                        Text("Create Group")
                    }
                }
            }) {
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
