import Foundation
import RxSwift

class CreatedRoom: ObservableObject {
    enum Event {
        case createdRoomsuccuss
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
    @Inject var firestoreDatabaseService: DatabaseServiceProtocol
    @Inject var userDefaultsService: UserDefaultsServiceProtocol

    func createdRoom() {
        roomInvitationCode = Room.generateRandomInvitationCode()
        
        firestoreDatabaseService.createNewRoom(
            Room(
                roomInvitationCode: roomInvitationCode,
                roomCapacity: setting.roomCapacity,
                isRoomPublic: setting.isRoomPublic,
                roomPassword: setting.roomPassword,
                rommHostID: userDefaultsService.getLoginState()?.userName ?? ""
                //TODO: 思考這邊有沒有不要是nil的辦法
            )
        )
        .subscribe(
            onSuccess: { [unowned self] in
                event = .createdRoomsuccuss
            },
            onFailure: { [unowned self] error in
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
