import RxSwift
import SwiftUI

class Login: ComposeObservableObject<Login.Event> {
    struct State {
        var userName: String = ""
        var userEmail: String = ""
        var connectionMessage: String = "Testing Firestore connection..."
        var isSignedIn: Bool = false
    }
    
    enum Event {
        case signInSuccess
    }
    
    @Published var state = State()
    
    @Inject private var loadingManager: LoadingManager
    @Inject var authService: AuthServiceProtocol
    @Inject var userDefaultsService: UserDefaultsServiceProtocol
    private let disposeBag = DisposeBag()
    
    func autoLogin() {
        if let loginstate = authService.getCurrentUserProfile() {
            publish(.event(.signInSuccess))
            userDefaultsService.setLoginState(
                PlayerLoginData(
                    userName: loginstate.name, userEmail: loginstate.email))
        } else {
            userDefaultsService.clearLoginState()
        }
    }
    
    func signInWithGoogle() {
        loadingManager.isLoading = true
        authService.signInWithGoogle()
            .subscribe(
                onSuccess: { [unowned self] userProfile in
                    state.userName = userProfile.name
                    state.userEmail = userProfile.email
                    state.isSignedIn = true
                    state.connectionMessage = "Successfully signed in!"
                    publish(.event(.signInSuccess))
                },
                onFailure: { [unowned self] error in
                    state.connectionMessage =
                    "Sign-in failed: \(error.localizedDescription)"
                    handleError(error)
                },
                onDisposed: { [unowned self] in
                    loadingManager.isLoading = false
                }
            )
            .disposed(by: disposeBag)
    }
    
    func handleError(_ error: Error) {
        let appError: AppError
        
        if let authError = error as? AuthServiceError {
            switch authError {
            case .invalidCredential:
                let message = "無效的憑證，需要重試"
                state.connectionMessage = message
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .userNotFound:
                let message = "帳戶為找到，請確認該帳戶是否存在"
                state.connectionMessage = message
                appError = AppError(message: message, underlyingError: error, navigateTo: .login)
            case .networkError:
                let message = "網路連線錯誤，請確認網路是否正常"
                state.connectionMessage = message
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .missingClientID:
                let message = "配置错误，缺少 Client ID。"
                state.connectionMessage = message
                appError = AppError(message: message, underlyingError: error, navigateTo: .login)
            case .googleSignInFailed(let signInError):
                let message = "Google登入失敗：\(signInError.localizedDescription)"
                state.connectionMessage = message
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .missingIDToken:
                let message = "缺少 ID Token，請重新嘗試"
                state.connectionMessage = message
                appError = AppError(message: message, underlyingError: error, navigateTo: .login)
            case .signOutFailed:
                let message = "登出失敗，請重新嘗試"
                state.connectionMessage = message
                appError = AppError(message: message, underlyingError: error, navigateTo: .login)
            case .firebaseError(let firebaseError):
                let message = "認證錯誤：\(firebaseError.localizedDescription)"
                state.connectionMessage = message
                appError = AppError(message: message, underlyingError: error, navigateTo: .login)
            case .unknownError:
                let message = "發生未知錯誤，請稍後重新嘗試"
                state.connectionMessage = message
                appError = AppError(message: message, underlyingError: error, navigateTo: .login)
            }
        } else {
            let message = "發生錯誤：\(error.localizedDescription)"
            state.connectionMessage = message
            appError = AppError(message: message, underlyingError: error, navigateTo: nil)
        }
        
        publish(.error(appError))
    }
}

