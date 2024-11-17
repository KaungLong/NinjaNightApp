import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Swinject

enum Pages: Hashable {
    case login
    case lobby
    case createdRoom
    case prepareRoom(roomInvitationCode: String)
}

class NavigationPathManager: ObservableObject {
    @Published var path = NavigationPath()
}

struct ContentView: View {
    @Inject private var authService: AuthServiceProtocol
    @StateObject private var navigationPathManager = NavigationPathManager()

    var body: some View {
        NavigationStack(path: $navigationPathManager.path) {
            LoginView()
                .navigationDestination(for: Pages.self) { page in
                    switch page {
                    case .login:
                        LoginView()
                    case .lobby:
                        LobbyView()
                    case .createdRoom:
                        CreatedRoomView()
                    case .prepareRoom(let roomInvitationCode):
                        RoomPrepareView(roomInvitationCode: roomInvitationCode)
                    }
                }
        }
        .environmentObject(navigationPathManager)
    }
}
