import FirebaseCore
import RxSwift
import SwiftUI

class RoomPrepare: ObservableObject {
    enum Event {

    }

    struct RoomInfo {
        var inviteCode: String = ""
        var currentPlayers: Int = 0
        var maxPlayers: Int = 0
        var hostName: String = ""
        var isPublic: Bool = false
    }

    let roomInvitationCode: String
    lazy var myPlayerData: Player = {
        let  playerName = userDefaultsService.getLoginState()?.userName ?? ""
        let player = Player(
            name: playerName,
            isReady: false,
            isOnline: true,
            lastHeartbeat: Timestamp(date: Date())
        )
        return player
    }()
    
    private let disposeBag = DisposeBag()

    @Published var roomInfo = RoomInfo()
    @Published var players = [Player]()
    @Published var isPlayerReady = false
    @Inject var firestoreDatabaseService: DatabaseServiceProtocol
    @Inject var userDefaultsService: UserDefaultsServiceProtocol

    init(roomInvitationCode: String) {
        self.roomInvitationCode = roomInvitationCode
    }
    
    func joinRoomFlow() {
        firestoreDatabaseService.fetchRoom(with: roomInvitationCode)
            .do(
                onSuccess: { [unowned self] roomSetting in
                    roomInfo.inviteCode = roomSetting.roomInvitationCode
                    roomInfo.hostName = roomSetting.rommHostID
                    roomInfo.isPublic = roomSetting.isRoomPublic
                    roomInfo.maxPlayers = roomSetting.roomCapacity
                }
            )
            .flatMap { [unowned self] room in
                self.firestoreDatabaseService.joinRoom(
                    roomID: room.id!, player: myPlayerData
                )
                .andThen(
                    self.firestoreDatabaseService.fetchPlayerList(forRoomWithID: room.id!)
                )
            }
            .subscribe(
                onSuccess: { [unowned self] players in
                    self.roomInfo.currentPlayers = players.count
                    self.players = players
                    print("Successfully joined room and fetched player list")
                },
                onFailure: { error in
                    self.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }


    func handleError(_ error: Error) {
        print("An error occurred: \(error.localizedDescription)")
    }
}

