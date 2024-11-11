import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = Login()
    @EnvironmentObject var navigationPathManager: NavigationPathManager

    var body: some View {
        BaseView(title: "登入遊戲") {
            LoginContentView(
                state: $viewModel.state,
                autoLogin: viewModel.autoLogin,
                signInWithGoogle: viewModel.signInWithGoogle
            )
            //TODO: 可以優化成onConsume搭配viewModel
            .onReceive(viewModel.$event) { event in
                guard let event = event else { return }
                switch event {
                case .signInSuccess:
                    //TODO: 這裡優化成可以限定Pages
                    navigationPathManager.path.append(Pages.lobby)
                case .signInFailure(let message):
                    print("Sign-in failed: \(message)")
                case .signOutSuccess:
                    print("Signed out successfully.")
                case .signOutFailure(let message):
                    print("Sign-out failed: \(message)")
                }
            }
        }
    }
}

struct LoginContentView: View {
    @Binding var state: Login.State
    var autoLogin: () -> Void
    var signInWithGoogle: () -> Void

    var body: some View {
        VStack {
            Text(state.connectionMessage)
            Button("Sign in with Google", action: signInWithGoogle)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .onAppear {
                    autoLogin()
                }
        }
    }
}

struct LoginContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginContentView(
            state: .constant(
                Login.State(
                    userName: "Preview User",
                    userEmail: "preview@example.com",
                    connectionMessage: "Testing connection..."
                )),
            autoLogin: {},
            signInWithGoogle: {}
        )
    }
}
