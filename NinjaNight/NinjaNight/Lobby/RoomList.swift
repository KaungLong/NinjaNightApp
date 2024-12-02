import SwiftUI
import RxSwift

class RoomList: ComposeObservableObject<RoomList.Event> {
    enum Event {
        case gotoSelectedRoom(String)
        case needPassword(Room)
    }
    
    private let disposeBag = DisposeBag()
    @Inject var roomListService: RoomListServiceProtocol
    @Inject private var loadingManager: LoadingManager
    
    @Published var rooms: [Room] = []
    @Published var selectedRoomInvitationCode: String = ""
    
    func tryToJoinRoom(room: Room) {
        if room.isRoomPrivate {
            publish(.event(.needPassword(room)))
        } else {
            publish(.event(.gotoSelectedRoom(room.roomInvitationCode)))
        }
    }
    
    func joinRoomWithPassword(room: Room, password: String) {
        if room.roomPassword == password {
            publish(.event(.gotoSelectedRoom(room.roomInvitationCode)))
        } else {
            publish(.error(AppError(message: "Incorrect password.", underlyingError: nil, navigateTo: nil)))
        }
    }
    
    func fetchRooms() {
        loadingManager.isLoading = true
        roomListService.fetchRoomsWithPlayerCounts()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [unowned self] fetchRooms in
                    rooms = fetchRooms
                },
                onFailure: { [unowned self] error in
                    handleError(error)
                },
                onDisposed: { [unowned self] in
                    loadingManager.isLoading = false
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func handleError(_ error: Error) {
        let appError: AppError

        if let serviceError = error as? RoomListServiceError {
            switch serviceError {
          
            case .databaseError(let dbError):
                appError = AppError(message: "Database error: \(dbError.localizedDescription)", underlyingError: error, navigateTo: nil)
            case .unknownError:
                appError = AppError(message: "  An unknown error occurred while fetching rooms: \(error.localizedDescription)", underlyingError: error, navigateTo: nil)
            }
        } else {
            appError = AppError(message: "An unexpected error occurred: \(error.localizedDescription)", underlyingError: error, navigateTo: nil)
        }

        publish(.error(appError))
    }
}
