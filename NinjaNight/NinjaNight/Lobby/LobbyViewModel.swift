import Foundation
import RxSwift

class LobbyViewModel: ObservableObject {
    enum Event {
        case signOutSuccess
        case signOutFailure(String)
    }

    @Published var event: Event?
    @Inject var authService: AuthServiceProtocol
    private let disposeBag = DisposeBag()
    
    @Published var isShowingJoinSheet = false
    
    func signOut() {
        authService.signOut()
            .subscribe(
                onCompleted: { [unowned self] in
                    event = .signOutSuccess
                },
                onError: { [unowned self] error in
                    event = .signOutFailure(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func codeAddingRoom () {
        isShowingJoinSheet = true
    }
}
