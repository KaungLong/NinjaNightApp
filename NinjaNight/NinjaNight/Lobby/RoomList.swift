import SwiftUI
import RxSwift

class RoomList: ComposeObservableObject<RoomList.Event> {
    enum Event {
 
    }
    
    private let disposeBag = DisposeBag()
    @Inject var roomListService: RoomListServiceProtocol
    @Inject private var loadingManager: LoadingManager
    
    @Published var rooms: [Room] = []
    @Published var selectedRoomInvitationCode: String = ""
    
    func fetchRooms() {
        loadingManager.isLoading = true
        roomListService.fetchRoomsWithPlayerCounts()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [unowned self] fetchRooms in
                    rooms = fetchRooms
                },
                onFailure: { [unowned self] error in

                },
                onDisposed: { [unowned self] in
                    loadingManager.isLoading = false
                }
            )
            .disposed(by: disposeBag)
    }
}
