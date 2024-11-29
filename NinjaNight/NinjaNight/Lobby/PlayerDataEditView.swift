import PhotosUI
import SwiftUI

struct PlayerDataEditView: View {
    @StateObject var viewModel: PlayerDataEdit = .init()
    @Environment(\.handleError) var handleError
    @EnvironmentObject private var alertManager: AlertManager
    
    var body: some View {
        BaseView {
            PlayerDataEditContentView(
                playerName: $viewModel.playerName,
                playerEmail: $viewModel.playerEmail,
                playerAvatar: $viewModel.playerAvatar,
                playerUid: $viewModel.playerUid,
                savePlayerName: viewModel.savePlayerName
            )
            .onConsume(handleError, viewModel, { event in
                switch event {
                case .saveSucceeded:
                    alertManager.showAlert(title: "提醒", message: "變更已保存！")
                }
            })
            .onAppear {
                viewModel.loadPlayerData()
            }
        }
    }
}

struct PlayerDataEditContentView: View {
    @Binding var playerName: String
    @Binding var playerEmail: String
    @Binding var playerAvatar: UIImage?
    @Binding var playerUid: String

    var savePlayerName: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if let avatar = playerAvatar {
                Image(uiImage: avatar)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .shadow(radius: 3)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(Text("Avatar").foregroundColor(.white))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                TextField("Enter your name", text: $playerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                Text(playerEmail)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("UID")
                    .font(.headline)
                Text(playerUid)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }

            Spacer()

            Button(action: {
                savePlayerName()
            }) {
                Text("Save Changes")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlayerDataEditContentView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerDataEditContentView(
            playerName: .constant("測試玩家"),
            playerEmail: .constant("test@gmail.com"),
            playerAvatar: .constant(nil),
            playerUid: .constant("fafe214314fef"),
            savePlayerName: {}
     
        )
    }
}
