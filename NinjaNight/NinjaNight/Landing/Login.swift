import RxSwift
import SwiftUI

class Login: ObservableObject {
    struct State {
        var userName: String = ""
        var userEmail: String = ""
        var connectionMessage: String = "Testing Firestore connection..."
        var isSignedIn: Bool = false
    }

    enum Event {
        case signInSuccess
        case signInFailure(String)
        case signOutSuccess
        case signOutFailure(String)
    }

    @Published var state = State()
    @Published var event: Event?

    @Inject var authService: AuthServiceProtocol
    @Inject var userDefaultsService: UserDefaultsServiceProtocol
    private let disposeBag = DisposeBag()

    func autoLogin() {
        if let loginstate = authService.getCurrentUserProfile() {
            event = .signInSuccess
            userDefaultsService.setLoginState(
                PlayerLoginData(
                    userName: loginstate.name, userEmail: loginstate.email))
        } else {
            userDefaultsService.clearLoginState()
        }
    }

    func signInWithGoogle() {
        authService.signInWithGoogle()
            .subscribe(
                onSuccess: { [unowned self] userProfile in
                    state.userName = userProfile.name
                    state.userEmail = userProfile.email
                    state.isSignedIn = true
                    state.connectionMessage = "Successfully signed in!"
                    event = .signInSuccess
                },
                onFailure: { [unowned self] error in
                    state.connectionMessage =
                        "Sign-in failed: \(error.localizedDescription)"
                    handleError(error)
                    event = .signInFailure(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }

    func signOut() {
        authService.signOut()
            .subscribe(
                onCompleted: { [unowned self] in
                    state.isSignedIn = false
                    state.userName = ""
                    state.userEmail = ""
                    state.connectionMessage = "Successfully signed out."
                    event = .signOutSuccess
                },
                onError: { [unowned self] error in
                    state.connectionMessage =
                        "Sign-out failed: \(error.localizedDescription)"
                    handleError(error)
                    event = .signOutFailure(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }

    //TODO: 應該要有一個環境值統一處理error事件
    func handleError(_ error: Error) {
        print("An error occurred: \(error.localizedDescription)")
    }
}
