import Foundation
import RxSwift

class CreatedRoom: ComposeObservableObject<CreatedRoom.Event>  {
    enum Event {
        case createdRoomSuccess(roomInvitationCode: String)
    }

    struct Setting {
        var roomName = ""
        var maximumCapacity = 5
        var isRoomPrivate = false
        var roomPassword = ""
    }

    private let disposeBag = DisposeBag()
    @Published var setting = Setting()
    var roomInvitationCode: String = ""

    @Inject var createRoomService: CreateRoomProtocol
    @Inject var userDefaultsService: UserDefaultsServiceProtocol
    
    func initRoomName() {
        setting.roomName = (userDefaultsService.getLoginState()?.userName ?? "") + "'s Room"
    }
    
    func createRoom() {
        roomInvitationCode = Room.generateRandomInvitationCode()
    
        let room = Room(
            roomInvitationCode: roomInvitationCode,
            roomName: setting.roomName,
            maximumCapacity: setting.maximumCapacity,
            isRoomPrivate: setting.isRoomPrivate,
            roomPassword: setting.roomPassword,
            rommHostID: userDefaultsService.getLoginState()?.userName ?? ""
        )

        createRoomService.createRoom(with: room)
            .subscribe(
                onCompleted: { [unowned self] in
                    publish(.event(.createdRoomSuccess(roomInvitationCode: roomInvitationCode)))
                },
                onError: { [unowned self] error in
                    handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    func handleError(_ error: Error) {
        let appError: AppError

        if let createRoomError = error as? CreateRoomError {
            switch createRoomError {
            case .invalidRoomData:
                let message = "Invalid room data provided."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .writeFailed(let firebaseError):
                let message = "Failed to create the room: \(firebaseError.localizedDescription)"
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .firebaseError(let firebaseError):
                let message = "Firebase error: \(firebaseError.localizedDescription)"
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            default:
                let message = "An unknown error occurred while creating the room."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            }
        } else {
            let message = "An unexpected error occurred: \(error.localizedDescription)"
            appError = AppError(message: message, underlyingError: error, navigateTo: nil)
        }

        publish(.error(appError))
    }
}
