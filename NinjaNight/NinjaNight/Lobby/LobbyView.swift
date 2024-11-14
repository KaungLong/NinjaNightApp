import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @StateObject var viewModel = LobbyViewModel()

    var body: some View {
        BaseView(title: "Lobby") {
            LobbyContentView(signOut: viewModel.signOut)
                .navigationBarHidden(true)
                .onReceive(viewModel.$event) { event in
                    guard let event = event else { return }
                    switch event {
                    case .signOutSuccess:
                        navigationPathManager.path = NavigationPath()
                    case .signOutFailure(let message):
                        print("Sign-out failed: \(message)")
                    }
                }
        }
    }
}

struct LobbyContentView: View {
    var signOut: () -> Void

    var body: some View {
        VStack {
            Text("Welcome to the Lobby!")
                .font(.largeTitle)
                .padding()
            Button("開始新遊戲", action: {})
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            Button("邀請碼加入", action: {})
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            Button("房間列表", action: {})
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            Button("玩家資料編輯", action: {})
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            Button("登出", action: signOut)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

struct LobbyContentView_Previews: PreviewProvider {
    static var previews: some View {
        LobbyContentView(signOut: {})
    }
}
