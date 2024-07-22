import Push
import SwiftUI

#Preview {
    DashBoard()
}

struct DashBoard: View {
    @State private var privateKey = ""

    @State private var address = ""
    @State private var pushUser: PushAPI? = nil
    @State private var pushStream: PushStream? = nil
    @State private var isLoading = false

    @State private var errorTitle: String = ""
    @State private var errorMessage: String = ""
    @State private var showingError: Bool = false

    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    func initPushWithRandomAccount() async throws {
        let privateKey = getRandomAccount()
        try await initPush(privateKey)
    }

    func initPush(_ privateKey: String) async throws {
        do {
            isLoading = true

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
        } catch {
            errorTitle = "Connection failed"
            errorMessage = "Error occured\n \(error)"
            showingError = true
        }
    }

    func disconnectWallet() async throws {
        pushUser = nil
        address = ""
        privateKey = ""
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
                    HStack {
                        TextField("Enter private key for test wallet", text: $privateKey).textFieldStyle(.roundedBorder)

                        Button("Add", action: {
                            Task {
                                if privateKey.count < 16 {
                                    try await initPush(privateKey)
                                }
                            }
                        })
                    }
                }
                .navigationTitle("Push Swift")
                .toolbar {
                    if isLoading {
                        ProgressView()

                    } else {
                        Button(action: {
                            Task {
                                try await initPushWithRandomAccount()
                            }

                        }) {
                            Text("Connect Random wallet")
                        }
                    }
                }.alert(errorTitle, isPresented: $showingError) { } message: {
                    Text(errorMessage)
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
                .alert(errorTitle, isPresented: $showingError) { } message: {
                    Text(errorMessage)
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

                if chats.isEmpty && !isLoading {
                    Text("Create a group to get started")
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

extension DashBoard {
    public func getRandomAccount() -> String {
        let length = 64
        let letters = "abcdef0123456789"
        let privateKey = String((0 ..< length).map { _ in letters.randomElement()! })

        return privateKey
    }
}
