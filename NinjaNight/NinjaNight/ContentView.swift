import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Swinject

struct ContentView: View {
    @Inject private var authService: AuthServiceProtocol
    @Inject private var loadingManager: LoadingManager

    @StateObject private var navigationPathManager = NavigationPathManager()
    @StateObject private var alertManager = AlertManager()

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
                    case .playerDataEdit:
                        PlayerDataEditView()
                    case .gameLoading(roomID: let roomID):
                        GameLoadingView(roomID: roomID)
                    }
                }
        }
        .environmentObject(navigationPathManager)
        .environmentObject(alertManager)
        .environment(\.handleError, handleError)
        .overlay(
            LoadingOverlay()
                .environmentObject(loadingManager)
        )
        .customAlert(
             title: alertManager.title,
             message: alertManager.message,
             isPresented: $alertManager.isPresented
         ) {
             alertManager.dismiss()
         }
    }
    
    func handleError(_ error: Error) {
        if let appError = error as? AppError {
            handleAppError(appError)
        } else {
            handleGenericError(error)
        }
    }

    private func handleAppError(_ appError: AppError) {
        alertManager.showAlert(
            title: "錯誤",
            message: appError.message,
            onDismiss: {
                if let page = appError.navigateTo {
                    navigationPathManager.path.append(page)
                } 
            }
        )
    }

    private func handleGenericError(_ error: Error) {
        alertManager.showAlert(
            title: "未知錯誤",
            message: error.localizedDescription,
            onDismiss: {
                navigationPathManager.path = NavigationPath()
            }
        )
    }
}


extension View {
    func customAlert(
        title: String,
        message: String,
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.alert(
            title,
            isPresented: isPresented,
            actions: {
                Button("OK", action: {
                    isPresented.wrappedValue = false 
                    onDismiss?()
                })
            },
            message: {
                Text(message)
            }
        )
    }
}

class AlertManager: ObservableObject {
    @Published var isPresented = false
    var title = ""
    var message = ""
    var onDismiss: (() -> Void)?
    
    func showAlert(title: String, message: String, onDismiss: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.onDismiss = onDismiss
        isPresented = true
    }
    
    func dismiss() {
        isPresented = false
        onDismiss?()
    }
}
