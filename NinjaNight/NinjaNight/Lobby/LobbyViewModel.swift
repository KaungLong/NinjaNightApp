import Foundation
import RxSwift

class LobbyViewModel: ComposeObservableObject<LobbyViewModel.Event> {
    enum Event {
        case signOutSuccess
    }

    @Inject var authService: AuthServiceProtocol
    private let disposeBag = DisposeBag()
    
    @Published var isShowingJoinSheet = false
    
    func signOut() {
        authService.signOut()
            .subscribe(
                onCompleted: { [unowned self] in
                    publish(.event(.signOutSuccess))
                },
                onError: { [unowned self] error in
                    handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func codeAddingRoom () {
        isShowingJoinSheet = true
    }
    
    func handleError(_ error: Error) {
        let appError: AppError

        if let authServiceError = error as? AuthServiceError {
            switch authServiceError {
            case .invalidCredential:
                let message = "Invalid credentials. Please try again."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .userNotFound:
                let message = "User not found. Please check your account."
                appError = AppError(message: message, underlyingError: error, navigateTo: .login)
            case .networkError:
                let message = "Network error. Please check your internet connection."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .signOutFailed:
                let message = "Failed to sign out. Please try again."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .unknownError:
                let message = "An unknown error occurred. Please try again later."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .firebaseError(let firebaseError):
                let message = "Firebase error: \(firebaseError.localizedDescription)"
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            default:
                let message = "An error occurred: \(error.localizedDescription)"
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            }
        } else {
            let message = "An unexpected error occurred: \(error.localizedDescription)"
            appError = AppError(message: message, underlyingError: error, navigateTo: nil)
        }

        publish(.error(appError))
    }
}
