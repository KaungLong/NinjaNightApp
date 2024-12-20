import FirebaseCore
import FirebaseFirestore
import RxSwift
import SwiftUI

class RoomPrepare: ComposeObservableObject<RoomPrepare.Event> {
    enum Event {
        case leaveRoom
        case roomNotExist
        case gameStart
        case roomFull
    }

    struct RoomInfo {
        var roomName: String = ""
        var inviteCode: String = ""
        var currentPlayers: Int = 0
        var minPlayers: Int = 0
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

    @Inject var roomPrepareService: RoomPrepareProtocol
    @Inject var userDefaultsService: UserDefaultsServiceProtocol
    private var playerListDisposable: Disposable?
    private var heartbeatDisposable: Disposable?
    private var roomExistenceDisposable: Disposable?
    private let disposeBag = DisposeBag()

    init(roomInvitationCode: String) {
        self.roomInvitationCode = roomInvitationCode
    }

    func joinRoomFlow() {
        roomPrepareService.fetchRoom(invitationCode: roomInvitationCode)
            .do(
                onSuccess: { [unowned self] roomSetting in
                    roomID = roomSetting.id
                    roomInfo.roomName = roomSetting.roomName
                    roomInfo.inviteCode = roomSetting.roomInvitationCode
                    roomInfo.hostName = roomSetting.rommHostID
                    roomInfo.isPublic = roomSetting.isRoomPrivate
                    roomInfo.minPlayers = roomSetting.minimumCapacity
                    roomInfo.maxPlayers = roomSetting.maximumCapacity

                    let currentUserName = userDefaultsService.getLoginState()?.userName ?? ""
                    isHost = (roomInfo.hostName == currentUserName)
                }
            )
            .flatMap { [unowned self] room in
                self.roomPrepareService.joinRoom(
                    roomID: room.id!, player: myPlayerData
                )
                .andThen(
                    self.roomPrepareService.fetchPlayerList(
                        roomID: room.id!
                    )
                )
            }
            .subscribe(
                onSuccess: { [unowned self] players in
                    print("Successfully joined room and fetched player list")
                    self.players = players
                    self.startListeningToPlayerList()
                    self.startHeartbeat()
                    self.startListeningToRoomExistence()
                },
                onFailure: { [unowned self] error in
                    self.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    func startGame() {
        publish(.event(.gameStart))
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
        roomPrepareService.deleteRoom(roomID: roomID)
            .subscribe(
                onCompleted: { [unowned self] in
                    self.publish(.event(.leaveRoom))
                },
                onError: { [unowned self] error in
                    self.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func removePlayer(roomID: String, playerName: String) {
        roomPrepareService.removePlayer(roomID: roomID, playerName: playerName)
            .subscribe(
                onCompleted: { [unowned self] in
                    self.publish(.event(.leaveRoom))
                },
                onError: { [unowned self] error in
                    self.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    func startListeningToPlayerList() {
        guard let roomID = self.roomID else { return }
        playerListDisposable = roomPrepareService.listenToPlayerList(
            roomID: roomID
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
        let withinPlayerLimits = (roomInfo.currentPlayers >= roomInfo.minPlayers &&
                                  roomInfo.currentPlayers <= roomInfo.maxPlayers)

        canStartGame = allReady && allAlive && withinPlayerLimits
    }

    func toggleReadyStatus() {
        guard let roomID = self.roomID else {
            print("Room ID not found.")
            return
        }

        isPlayerReady.toggle()
        myPlayerData.isReady = isPlayerReady

        roomPrepareService.updatePlayerReadyStatus(
            roomID: roomID,
            playerName: myPlayerData.name,
            isReady: isPlayerReady
        )
        .subscribe(
            onCompleted: {
                print("Player ready status updated successfully.")
            },
            onError: { [unowned self] error in
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
            return self.roomPrepareService.updatePlayerHeartbeat(
                roomID: roomID,
                playerName: updatedPlayer.name,
                lastHeartbeat: updatedPlayer.lastHeartbeat
            )
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

    func startListeningToRoomExistence() {
        guard let roomID = self.roomID else {
            print("Room ID not found.")
            return
        }

        roomExistenceDisposable = roomPrepareService.listenToRoomUpdates(roomID: roomID)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onError: { [unowned self] error in
                    if case RoomPrepareError.roomNotFound = error {
                        publish(.event(.roomNotExist))
                    } else {
                        handleError(error)
                    }
                }
            )
    }
    
    func stopListeningToRoomExistence() {
        roomExistenceDisposable?.dispose()
        roomExistenceDisposable = nil
    }


    deinit {
        stopListeningToPlayerList()
        stopHeartbeat()
        stopListeningToRoomExistence()
    }

    func handleError(_ error: Error) {
        if let roomPrepareError = error as? RoomPrepareError {
            switch roomPrepareError {
            case .roomFull:
                publish(.event(.roomFull))
            default:
                let message = roomPrepareError.errorDescription ?? "An error occurred."
                let appError = AppError(message: message, underlyingError: error, navigateTo: nil)
                publish(.error(appError))
            }
        } else {
            let message = "An unexpected error occurred: \(error.localizedDescription)"
            let appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            publish(.error(appError))
        }
    }
}
