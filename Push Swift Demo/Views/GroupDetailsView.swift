import Push
import SwiftUI

struct GroupDetailsView: View {
    let groupInfo: PushChat.PushGroupInfoDTO
    let pushUser: PushAPI
    
    @State var groupMembers : [PushChat.ChatMemberProfile] = []
    @State var isLoading = false
    
    func getMembers() async throws {
        do {
            let members = try await pushUser.chat.group.participants.list(chatId: groupInfo.chatId)
            if(members != nil){
                groupMembers = members!
            }
            isLoading = false
        }catch {
            isLoading = false
        }
        
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Group Name") {
                    Text(groupInfo.groupName).font(.caption)
                }
                Section("Group Chat Id") {
                    Text(groupInfo.chatId).font(.caption)
                }
                Section("Group description") {
                    Text(groupInfo.groupDescription).font(.caption)
                }
                Section("Group Creator") {
                    Text(groupInfo.groupCreator).font(.caption)
                }
                Section("Group Type") {
                    Text(groupInfo.isPublic ? "Public Group" : "Private Group").font(.caption)
                }
                Section ("Members") {
                    List(groupMembers, id: \.address) { member in
                        VStack {
                            Text(member.address).font(.system(size: 16))
                            Text(member.role).font(.footnote).frame(alignment: .trailing)
                            
                        }
                    }
                }
            }.navigationTitle("Group Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if isLoading {
                        ProgressView()
                    }
                }
        }.onAppear(){
            Task {
                try await getMembers()
            }
        }
    }
}
