import Foundation
import Push
import SwiftUI

struct ChatView: View {
    var feed: Push.PushChat.Feeds
    var pushUser: PushAPI

    init(feed: Push.PushChat.Feeds, pushUser: PushAPI) {
        self.feed = feed
        self.pushUser = pushUser

        if feed.msg != nil {
            messages = [feed.msg!]
        }
    }

    @State private var newMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var messages: [Message] = []

    var body: some View {
        VStack(alignment: .leading) {
            if messages.isEmpty && isLoading {
                VStack(alignment: .center) {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if messages.isEmpty && !isLoading {
                VStack(alignment: .center) {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("No messages found")
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                List(messages, id: \.cid) {
                    message in VStack(alignment: .leading) {
                        ChatMessageView(
                            sender: message.fromCAIP10,
                            message: message.messageObj?.content ?? "",
                            direction: walletToPCAIP10(account: pushUser.account) == message.fromCAIP10 ? .right : .left
                        )
                    }
                }.listStyle(.plain).listRowSeparator(.hidden).padding(8)
            }

            HStack {
                TextField("Enter message", text: $newMessage).textFieldStyle(.roundedBorder)
                Button(action: {
                    Task {
                        try await sendMesage()
                    }

                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill").foregroundColor(.purple)
                    }
                }
            }.padding(8)
        }
        .navigationTitle(feed.groupInformation?.groupName ?? feed.chatId ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            HStack {
                if isLoading {
                    ProgressView()
                } else if feed.groupInformation != nil {
                    NavigationLink(destination: GroupDetailsView(
                        groupInfo: feed.groupInformation!,
                        pushUser: pushUser)) {
                            Image(systemName: "person.3.fill")
                        }
                }
            }
        }
        .onAppear(perform: {
            Task {
                await _init()
            }

        })
    }

    func sendMesage() async throws {
        do {
            isLoading = true
            let payload = PushChat.SendMessage(content: newMessage, type: .Text)
            let _ = try await pushUser.chat.send(target: feed.chatId!, message: payload)
            await loadMessages()
            isLoading = false
            newMessage = ""
        } catch {
            isLoading = false
            print("sendMesage:  An error occured")
        }
    }

    func _init() async {
        await loadMessages()

        let pushStream = pushUser.stream

        pushStream?.on(STREAM.CHAT.rawValue, listener: { it in
            print("Scocket CHAT: in chat \((it as! [String: Any])["chatId"] as! String)")
            if ((it as! [String: Any])["chatId"] as! String) == feed.chatId {
                Task {
                    await loadMessages()
                }
            }

        })

        pushStream?.on(STREAM.CHAT_OPS.rawValue, listener: { it in
            print("Scocket CHAT: in chat \((it as! [String: Any])["chatId"] as! String)")
            if ((it as! [String: Any])["chatId"] as! String) == feed.chatId {
                Task {
                    await loadMessages()
                }
            }

        })
    }

    func loadMessages() async {
        do {
            isLoading = true
            let chats = try await pushUser.chat.history(target: feed.chatId!)

            messages = chats.reversed()
            isLoading = false
        } catch {
            print("loadMessages:  An error occured")
        }
    }
}

enum ChatMessageDirection {
    case left
    case right
}

struct ChatMessageView: View {
    let sender: String
    let message: String
    let direction: ChatMessageDirection

    var body: some View {
        HStack {
            if direction == .right {
                Spacer()
            }
            VStack(alignment: direction == .left ? .leading : .trailing) {
                Text(sender).font(.system(size: 8))
                Text(message)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                    .listRowSeparator(.hidden)
                    .overlay(alignment: direction == .left ? .bottomLeading : .bottomTrailing) {
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.title)
                            .rotationEffect(.degrees(direction == .left ? 45 : -45))
                            .offset(x: direction == .left ? -10 : 10, y: 10)
                            .foregroundColor(.blue)
                    }
            }
        }.listRowSeparator(.hidden)
    }
}

// #Preview {
//    ChatView(feed: nil, pushUser: nil)
// }
