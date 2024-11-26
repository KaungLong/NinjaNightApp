import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = Login()
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @Environment(\.handleError) var handleError

    var body: some View {
        BaseView(title: "登入遊戲") {
            LoginContentView(
                state: $viewModel.state,
                autoLogin: viewModel.autoLogin,
                signInWithGoogle: viewModel.signInWithGoogle
            )
            .onConsume(handleError, viewModel) { event in
                switch event {
                case .signInSuccess:
                    navigationPathManager.path.append(
                        Pages.lobby
                    )
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
                )
            ),
            autoLogin: {},
            signInWithGoogle: {}
        )
    }
}
