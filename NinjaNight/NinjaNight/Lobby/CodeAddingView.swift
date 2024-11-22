import SwiftUI

struct CodeAddingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @ObservedObject var viewModel: CodeAddingViewModel = .init()

    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        CodeAddingContentView(
            invitationCodeInput: $viewModel.invitationCodeInput,
            isPresented: $isPresented,
            showAlert: $viewModel.showAlert,
            alertMessage: $viewModel.alertMessage,
            checkIfRoomExists: viewModel.checkIfRoomExists
        )
        .padding()
        .onReceive(viewModel.$event) { event in
            guard let event = event else { return }
            switch event {
            case .roomExist:
                isPresented = false
                navigationPathManager.path.append(
                    Pages.prepareRoom(
                        roomInvitationCode: viewModel.invitationCodeInput))
            case .failure(_):
                print("failure")
            }
        }

 
    }
}

struct CodeAddingContentView: View {
    @Binding var invitationCodeInput: String
    @Binding var isPresented: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    var checkIfRoomExists: () -> Void

    var body: some View {
        VStack {
            Text("輸入邀請碼加入房間")
                .font(.headline)
                .padding()
            TextField("邀請碼", text: $invitationCodeInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numberPad)
            HStack {
                Button("取消") {
                    isPresented = false
                    invitationCodeInput = ""
                }
                .padding()
                Spacer()
                Button("加入") {
                    guard !invitationCodeInput.isEmpty else {
                        alertMessage = "請輸入邀請碼～"
                        showAlert = true
                        return
                    }

                    checkIfRoomExists()
                }
            }
            .padding()
        }
        .padding()
    }
}



