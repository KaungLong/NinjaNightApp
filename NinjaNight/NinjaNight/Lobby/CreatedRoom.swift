import Foundation
import RxSwift

class CreatedRoom: ObservableObject {
    enum Event {
        case createdRoomSuccess
        case createdRoomFailure(String)
    }

    struct Setting {
        var roomCapacity = 5
        var isRoomPublic = true
        var roomPassword = ""
    }

    private let disposeBag = DisposeBag()
    @Published var setting = Setting()
    @Published var event: Event?
    var roomInvitationCode: String = ""

    @Inject var createRoomService: CreateRoomProtocol
    @Inject var userDefaultsService: UserDefaultsServiceProtocol

    func createRoom() {
        roomInvitationCode = Room.generateRandomInvitationCode()
        
        let room = Room(
            roomInvitationCode: roomInvitationCode,
            roomCapacity: setting.roomCapacity,
            isRoomPublic: setting.isRoomPublic,
            roomPassword: setting.roomPassword,
            rommHostID: userDefaultsService.getLoginState()?.userName ?? ""
        )

        createRoomService.createRoom(with: room)
            .subscribe(
                onCompleted: { [unowned self] in
                    event = .createdRoomSuccess
                },
                onError: { [unowned self] error in
                    handleError(error)
                    event = .createdRoomFailure(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }

    func handleError(_ error: Error) {
        print("An error occurred: \(error.localizedDescription)")
    }
}
