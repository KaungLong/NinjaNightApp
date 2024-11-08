import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @StateObject var viewModel = LobbyViewModel()

    var body: some View {
        VStack {
            Text("Welcome to the Lobby!")
                .font(.largeTitle)
                .padding()
            Button("Sign Out", action: viewModel.signOut)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
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
