import Push
import SwiftUI



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
