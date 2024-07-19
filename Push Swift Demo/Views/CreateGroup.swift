
import Push
import SwiftUI

// #Preview {
//    CreateGroup()
// }

struct CreateGroup: View {
    var pushUser: PushAPI
    let onClose: () -> Void

    @State private var toastMessage: String = ""
    @State private var errorTitle: String = ""
    @State private var errorMessage: String = ""
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var adminAddress: String = ""
    @State private var memberAddress: String = ""
    @State private var allMemberAddress: [String] = []
    @State private var allAdminAddress: [String] = []
    @State private var isPublic: Bool = true
    @State private var isLoading: Bool = false
    @State private var showingError: Bool = false

    @State private var showToast = false

    func showError(title: String = "Cannot create group", message: String = "Try again") {
        errorTitle = title
        errorMessage = message
        showingError = true
    }

    func onCreateGroup() async throws {
        if isLoading {
            return
        }

        if groupName.isEmpty {
            showError(message: "Enter Group Name")
            return
        }
        if groupDescription.isEmpty {
            showError(message: "Enter Group Description")
            return
        }
        if allMemberAddress.isEmpty {
            showError(message: "Add member")
            return
        }

        do {
            let options = Group.GroupCreationOptions(
                description: groupDescription,
                image: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAIAAADTED8xAAADMElEQVR4nOzVwQnAIBQFQYXff81RUkQCOyDj1YOPnbXWPmeTRef+/3O/OyBjzh3CD95BfqICMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMO0TAAD//2Anhf4QtqobAAAAAElFTkSuQmCC",
                members: allMemberAddress,
                admins: allAdminAddress,
                isPrivate: !isPublic)

            print("options: \(options)")

            isLoading = true
            let group = try await pushUser.chat.group.create(name: groupName, options: options)
            print("group: \(String(describing: group))")
            if group != nil {
                toastMessage = "Group Created successfully"
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                    onClose()
                }
            }
            isLoading = false
        } catch {
            errorTitle = "Cannot create group"
            errorMessage = "error creating group \(error)"
            showingError = true
            isLoading = false
        }
    }

    func onAddAdmin() {
        if isValidETHAddress(address: adminAddress) {
            allAdminAddress.append(adminAddress)
            adminAddress = ""
        } else {
            showingError = true
            errorTitle = "Invalid Address"
            errorMessage = "Check address and try again"
        }
    }

    func onAddMember() {
        if isValidETHAddress(address: memberAddress) {
            allMemberAddress.append(memberAddress)
            memberAddress = ""
        } else {
            showingError = true
            errorTitle = "Invalid Address"
            errorMessage = "Check address and try again"
        }
    }

    func onTogglePublic() {
        isPublic = !isPublic
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section("Admins") {
                        VStack(alignment: .leading) {
                            if allAdminAddress.isEmpty {
                                Text("No admin added")
                            }

                            if !allAdminAddress.isEmpty {
                                List(allAdminAddress, id: \.self) { address in
                                    HStack {
                                        Text(address)
                                        Spacer()

                                        Button(action: {
                                            allAdminAddress.removeAll { $0 == address }

                                        }) {
                                            Image(systemName: "trash")
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Section("Members") {
                        VStack(alignment: .leading) {
                            if allMemberAddress.isEmpty {
                                Text("No member added")
                            }

                            if !allMemberAddress.isEmpty {
                                List(allMemberAddress, id: \.self) { address in
                                    HStack {
                                        Text(address)
                                        Spacer()

                                        Button(action: {
                                            allMemberAddress.removeAll { $0 == address }

                                        }) {
                                            Image(systemName: "trash")
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    TextField("Enter Group Name", text: $groupName).textFieldStyle(.roundedBorder)
                    TextField("Enter Group Description", text: $groupDescription).textFieldStyle(.roundedBorder)

                    HStack {
                        TextField("Add Admin Adress", text: $adminAddress).textFieldStyle(.roundedBorder)

                        Button("Add", action: onAddAdmin)
                    }

                    HStack {
                        TextField("Add Member Adress", text: $memberAddress).textFieldStyle(.roundedBorder)

                        Button("Add", action: onAddMember)
                    }

                    Toggle(isOn: $isPublic) {
                        Text("Is this a public group")
                    }
                }

                if showToast {
                    ToastView(message: toastMessage)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
        .toolbar {
            HStack {
                if isLoading {
                    ProgressView()
                }

                Button(action: {
                    Task {
                        print("Create group")
                        try await onCreateGroup()
                    }

                }) {
                    Text("Create")
                }
            }
        }
        .navigationTitle("Create Group")
        .navigationBarTitleDisplayMode(.inline)
        .alert(errorTitle, isPresented: $showingError) { } message: {
            Text(errorMessage)
        }
    }
}
