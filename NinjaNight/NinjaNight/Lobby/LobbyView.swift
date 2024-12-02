import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @Environment(\.handleError) var handleError
    @StateObject var viewModel = LobbyViewModel()
    @Inject private var loadingManager: LoadingManager

    var body: some View {
        BaseView(title: "Lobby") {
            LobbyContentView(
                signOut: viewModel.signOut,
                gotoSettingNewRoom: {
                    navigationPathManager.navigate(to: .createdRoom)
                },
                gotoCodeAddingRoom: viewModel.codeAddingRoom,
                gotoRoomList: {
                    navigationPathManager.navigate(to: .roomList)
                },
                gotoPlayerDataEdit: {
                    navigationPathManager.navigate(to: .playerDataEdit)
                }
                
            )
            .navigationBarHidden(true)
            .onConsume(handleError, viewModel) { event in
                switch event {
                case .signOutSuccess:
                    navigationPathManager.popToRoot()
                }
            }
            .sheet(isPresented: $viewModel.isShowingJoinSheet) {
                CodeAddingView(isPresented: $viewModel.isShowingJoinSheet)
                    .presentationDetents([.height(200)])
            }
        }
    }
}

struct LobbyContentView: View {
    var signOut: () -> Void
    var gotoSettingNewRoom: () -> Void
    var gotoCodeAddingRoom: () -> Void
    var gotoRoomList:() -> Void
    var gotoPlayerDataEdit: () -> Void

    var body: some View {
        VStack {
            Text("Welcome to the Lobby!")
                .font(.largeTitle)
                .padding()
            Button("開始新遊戲", action: gotoSettingNewRoom)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            Button("邀請碼加入", action: gotoCodeAddingRoom)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            Button("房間列表", action: gotoRoomList)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            Button("玩家資料編輯", action: gotoPlayerDataEdit)
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
        LobbyContentView(
            signOut: {},
            gotoSettingNewRoom: {},
            gotoCodeAddingRoom: {},
            gotoRoomList: {},
            gotoPlayerDataEdit: {}
        )
    }
}
