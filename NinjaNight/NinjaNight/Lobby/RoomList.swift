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
