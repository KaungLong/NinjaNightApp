import Foundation
import RxSwift

class CodeAdding: ComposeObservableObject<CodeAdding.Event> {
    enum Event {
        case roomExist
    }

    @Published var invitationCodeInput = ""
    @Published var showAlert = false
    @Published var alertMessage = ""

    @Inject private var codeAddingService: CodeAddingProtocol
    @Inject private var loadingManager: LoadingManager

    private let disposeBag = DisposeBag()

    func checkIfRoomExists() {
        guard !invitationCodeInput.isEmpty else {
            alertMessage = "邀請碼不能為空！"
            showAlert = true
            return
        }

        loadingManager.isLoading = true
        codeAddingService.checkRoomExists(invitationCode: invitationCodeInput)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [unowned self] exists in
                    if exists {
                        publish(.event(.roomExist))
                    } else {
                        alertMessage = "該房間不存在！"
                        showAlert = true
                    }
                    invitationCodeInput = ""
                },
                onFailure: { [unowned self] error in
                    print("Error checking if room exists: \(error.localizedDescription)")
                    alertMessage = "檢查房間時出錯！"
                    showAlert = true
                    invitationCodeInput = ""
                },
                onDisposed: { [unowned self] in
                    loadingManager.isLoading = false
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func handleError(_ error: Error) {
           let appError: AppError

           if let codeAddingError = error as? CodeAddingError {
               switch codeAddingError {
               case .roomNotFound:
                   let message = codeAddingError.errorDescription ?? "Room not found."
                   appError = AppError(message: message, underlyingError: error, navigateTo: nil)
               case .readFailed(let firebaseError):
                   let message = "Failed to read room data: \(firebaseError.localizedDescription)"
                   appError = AppError(message: message, underlyingError: error, navigateTo: nil)
               case .firebaseError(let firebaseError):
                   let message = "Firebase error: \(firebaseError.localizedDescription)"
                   appError = AppError(message: message, underlyingError: error, navigateTo: nil)
               default:
                   let message = "An unknown error occurred."
                   appError = AppError(message: message, underlyingError: error, navigateTo: nil)
               }
           } else {
               let message = "An unexpected error occurred: \(error.localizedDescription)"
               appError = AppError(message: message, underlyingError: error, navigateTo: nil)
           }

           publish(.error(appError))
       }
}
