import FirebaseCore
import FirebaseFirestore
import RxSwift
import SwiftUI

class RoomPrepare: ObservableObject {
    enum Event {
        case leaveRoom
        case gameStart
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
        let playerName = userDefaultsService.getLoginState()?.userName ?? ""
        let player = Player(
            name: playerName,
            isReady: isHost,
            isOnline: true,
            lastHeartbeat: Timestamp(date: Date())
        )
        return player
    }()

    @DocumentID var roomID: String?
    @Published var roomInfo = RoomInfo()
    @Published var players = [Player]()
    @Published var isPlayerReady = false
    @Published var isHost = false
    @Published var canStartGame = false
    @Published var event: Event?
    
    @Inject var firestoreDatabaseService: DatabaseServiceProtocol
    @Inject var userDefaultsService: UserDefaultsServiceProtocol
    private var playerListDisposable: Disposable?
    private var heartbeatDisposable: Disposable?
    private let disposeBag = DisposeBag()

    init(roomInvitationCode: String) {
        self.roomInvitationCode = roomInvitationCode
    }

    func joinRoomFlow() {
        firestoreDatabaseService.fetchRoom(with: roomInvitationCode)
            .do(
                onSuccess: { [unowned self] roomSetting in
                    roomID = roomSetting.id
                    roomInfo.inviteCode = roomSetting.roomInvitationCode
                    roomInfo.hostName = roomSetting.rommHostID
                    roomInfo.isPublic = roomSetting.isRoomPublic
                    roomInfo.maxPlayers = roomSetting.roomCapacity

                    let currentUserName =
                        userDefaultsService.getLoginState()?.userName ?? ""
                    if roomInfo.hostName == currentUserName {
                        isHost = true
                    } else {
                        isHost = false
                    }
                }
            )
            .flatMap { [unowned self] room in
                self.firestoreDatabaseService.joinRoom(
                    roomID: room.id!, player: myPlayerData
                )
                .andThen(
                    self.firestoreDatabaseService.fetchPlayerList(
                        forRoomWithID: room.id!)
                )
            }
            .subscribe(
                onSuccess: { [unowned self] players in
                    print("Successfully joined room and fetched player list")
                    startListeningToPlayerList()
                    startHeartbeat()
                },
                onFailure: { error in
                    self.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func startGame() {
        event = .gameStart
    }
    
    func leaveRoom() {
        guard let roomID = self.roomID else {
            print("Room ID not found.")
            return
        }

        stopListeningToPlayerList()
        stopHeartbeat()

        if isHost {
            deleteRoom(roomID: roomID)
        } else {
            removePlayer(roomID: roomID, playerName: myPlayerData.name)
        }
    }

    private func deleteRoom(roomID: String) {
        firestoreDatabaseService.deleteRoom(withID: roomID)
            .subscribe(
                onCompleted: {
                    print("Room \(roomID) deleted successfully by host.")
                    self.event = .leaveRoom
                },
                onError: { error in
                    self.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func removePlayer(roomID: String, playerName: String) {
        firestoreDatabaseService.removePlayer(roomID: roomID, playerName: playerName)
            .subscribe(
                onCompleted: {
                    print("Player \(playerName) successfully removed from room.")
                    self.event = .leaveRoom
                },
                onError: { error in
                    self.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }


    func startListeningToPlayerList() {
        guard let roomID = self.roomID else { return }
        playerListDisposable = firestoreDatabaseService.listenToPlayerList(
            forRoomWithID: roomID
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onNext: { [weak self] players in
                self?.players = players
                self?.roomInfo.currentPlayers = players.count
                self?.checkIfAllPlayersReadyAndAlive()
            },
            onError: { [weak self] error in
                self?.handleError(error)
            }
        )
    }
    
    private func checkIfAllPlayersReadyAndAlive() {
        let allReady = players.allSatisfy { $0.isReady }
        let allAlive = players.allSatisfy {
            let lastHeartbeatDate = $0.lastHeartbeat.dateValue()
            return Date().timeIntervalSince(lastHeartbeatDate) < 30
        }

        canStartGame = allReady && allAlive
        print("Can start game: \(canStartGame)")
    }
    
    func toggleReadyStatus() {
        guard let roomID = self.roomID else {
            print("Room ID not found.")
            return
        }

        isPlayerReady.toggle()
        myPlayerData.isReady = isPlayerReady

        firestoreDatabaseService.updatePlayerReadyStatus(
            roomID: roomID,
            playerName: myPlayerData.name,
            isReady: isPlayerReady
        )
        .subscribe(
            onCompleted: {
                print("Player ready status updated successfully.")
            },
            onError: { error in
                self.handleError(error)
            }
        )
        .disposed(by: disposeBag)
    }

    func stopListeningToPlayerList() {
        playerListDisposable?.dispose()
        playerListDisposable = nil
    }

    func startHeartbeat() {
        guard let roomID = self.roomID else { return }

        heartbeatDisposable = Observable<Int>.interval(
            .seconds(5), scheduler: MainScheduler.instance
        )
        .flatMap { [unowned self] _ -> Completable in
            var updatedPlayer = self.myPlayerData
            updatedPlayer.lastHeartbeat = Timestamp(date: Date())
            return self.firestoreDatabaseService.updatePlayerHeartbeat(
                roomID: roomID,
                playerName: updatedPlayer.name,
                lastHeartbeat: updatedPlayer.lastHeartbeat
            )
            .do(onCompleted: {
                  print("Heartbeat updated successfully at \(Date())")
              })
        }
        .subscribe(
            onError: { [unowned self] error in
                self.handleError(error)
            }
        )
    }

    func stopHeartbeat() {
        heartbeatDisposable?.dispose()
        heartbeatDisposable = nil
    }

    deinit {
        stopListeningToPlayerList()
    }

    func handleError(_ error: Error) {
        print("An error occurred: \(error.localizedDescription)")
    }
}
