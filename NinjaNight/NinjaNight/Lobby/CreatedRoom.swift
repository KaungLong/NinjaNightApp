import Foundation
import RxSwift

class CreatedRoom: ObservableObject {
    enum Event {
        case succuss
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
    @Inject var firestoreDatabaseService: DatabaseServiceProtocol
    
    func createdRoom() {
        let roomInvitationCode = Room.generateRandomInvitationCode()
        
        firestoreDatabaseService.createNewRoom(
            Room(
                roomInvitationCode: roomInvitationCode,
                roomCapacity: setting.roomCapacity,
                isRoomPublic: setting.isRoomPublic,
                roomPassword: setting.roomPassword)
        )
        .subscribe(
            onSuccess: { [unowned self] in
                event = .succuss
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
