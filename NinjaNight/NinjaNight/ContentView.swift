import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Swinject

struct ContentView: View {
    @Inject private var authService: AuthServiceProtocol
    @Inject private var loadingManager: LoadingManager
    @State private var showingAlert = false
    @State private var errorMessage = ""

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
                    case .roomList:
                        RoomListView()
                    }
                }
        }
        .environmentObject(navigationPathManager)
        .environment(\.handleError, handleError)
        .overlay(
                LoadingOverlay()
                    .environmentObject(loadingManager)
            )
        .alert("錯誤", isPresented: $showingAlert, actions: {
            Button("OK") {
                navigationPathManager.path = NavigationPath()
            }
        }, message: {
            Text(errorMessage)
        })
    }
    
    func handleError(_ error: Error) {
        if let appError = error as? AppError {
            errorMessage = appError.message
            showingAlert = true

            if let page = appError.navigateTo {
                navigationPathManager.path.append(page)
            } else {
                navigationPathManager.path = NavigationPath()
            }
        } else {
            errorMessage = error.localizedDescription
            showingAlert = true
            navigationPathManager.path = NavigationPath()
        }
    }
}

