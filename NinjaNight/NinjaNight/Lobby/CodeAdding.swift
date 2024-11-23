import Foundation
import RxSwift

class CodeAddingViewModel: ObservableObject {
    enum Event {
        case roomExist
        case failure(String)
    }

    @Published var event: Event?
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
                        event = .roomExist
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
}
