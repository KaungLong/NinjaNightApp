import Foundation
import RxSwift
import SwiftUI

class GameLoading: ComposeObservableObject<GameLoading.Event> {
    enum Event {
        case loadingDone(String)
    }

    let initialHandCards = 3
    @Published var roomID: String = ""
    @Published var playerCards: [String: [Card]] = [:]
    @Published var factionCards: [Faction] = []
    @Published var honerMarks: [HonerMark] = []
    @Published var currentSettingProgress: Double = 0.0
    @Published var loadingMessage: String = ""
    @Published var isHost: Bool = false

    init(roomID: String) {
        self.roomID = roomID
    }

    @Inject private var gameLoadingService: GameLoadingServiceProtocol
    @Inject private var userDefaultsService: UserDefaultsServiceProtocol
    private let disposeBag = DisposeBag()

    func checkHost() -> Single<Bool> {
        gameLoadingService.fetchRoom(roomID: roomID)
            .map { [weak self] room in
                guard let self = self else { return false }

                let currentUserName =
                    self.userDefaultsService.getLoginState()?.userName ?? ""
                let isHost = currentUserName == room.rommHostID

                DispatchQueue.main.async {
                    self.isHost = isHost
                }

                return isHost
            }
            .do(
                onSuccess: { isHost in
                    let message =
                        isHost
                        ? "Start setting."
                        : "Waiting for host to start setting."
                    self.updateProgress(message: message, progress: 0.0)
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                }
            )
    }

    func setupGame() {
        checkHost()
            .flatMapCompletable { isHost -> Completable in
                if isHost {
                    return self.fetchPlayers()
                        .flatMapCompletable { players in
                            self.configureDeck(players: players)
                                .andThen(
                                    self.configureFactionDeck(players: players)
                                )
                                .andThen(self.configureHonerMarks())
                                .andThen(
                                    self.playerRoundStateInitial(players: players))
                        }
                } else {
                    self.startListeningToRoomUpdates()
                    return Completable.empty()
                }
            }
            .subscribe(
                onCompleted: {
                    self.updateProgress(
                        message: "Game setup completed successfully.",
                        progress: 1.0)
                    self.publish(
                        .event(
                            .loadingDone("Game setup completed successfully.")))
                },
                onError: { error in
                    self.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func startListeningToRoomUpdates() {
        gameLoadingService.listenToRoom(roomID: roomID)
            .subscribe(
                onNext: { [weak self] room in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        self.currentSettingProgress = room.currentSettingProgress
                        self.loadingMessage = room.loadingMessage
                    }
                    
                    if room.currentSettingProgress >= 1.0 {
                        self.publish(
                            .event(
                                .loadingDone("Game setup completed successfully.")))
                    }
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func updateProgress(message: String, progress: Double) {
        DispatchQueue.main.async {
            self.loadingMessage = message
            self.currentSettingProgress = progress
        }

        gameLoadingService.updateProgress(
            roomID: roomID, progress: progress, message: message
        )
        .subscribe(
            onCompleted: {
                print("Room progress updated successfully.")
            },
            onError: { error in
                self.handleError(error)
            }
        )
        .disposed(by: disposeBag)
    }

    private func fetchPlayers() -> Single<[Player]> {
        gameLoadingService.fetchPlayers(roomID: roomID)
            .do(
                onSuccess: { [weak self] players in
                    self?.updateProgress(
                        message: "Fetched players successfully.", progress: 0.1)
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                })
    }

    private func configureDeck(players: [Player]) -> Completable {
        Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(GameLoadingError.unknownError))
                return Disposables.create()
            }

            let numberOfPlayers = players.count

            self.gameLoadingService.createRoundDeck(
                numberOfPlayers: numberOfPlayers,
                initialHandCards: self.initialHandCards
            )
            .subscribe(
                onSuccess: { cards in
                    self.distributePlayerCards(cards: cards, players: players)
                    self.updateProgress(
                        message: "Deck configured successfully.", progress: 0.3)
                    completable(.completed)
                },
                onFailure: { error in
                    self.handleError(error)
                    completable(.error(error))
                }
            )
            .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    private func distributePlayerCards(cards: [Card], players: [Player]) {
        var cardIndex = 0
        playerCards = players.reduce(into: [:]) { result, player in
            result[player.name] = Array(
                cards[cardIndex..<(cardIndex + initialHandCards)])
            cardIndex += initialHandCards
        }
    }

    private func configureFactionDeck(players: [Player]) -> Completable {
        Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(GameLoadingError.unknownError))
                return Disposables.create()
            }

            let numberOfPlayers = players.count

            self.gameLoadingService.createFactionDeck(
                numberOfPlayers: numberOfPlayers
            )
            .subscribe(
                onSuccess: { factions in
                    self.factionCards = factions
                    self.updateProgress(
                        message: "Faction deck configured successfully.",
                        progress: 0.6)
                    completable(.completed)
                },
                onFailure: { error in
                    self.handleError(error)
                    completable(.error(error))
                }
            )
            .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    private func configureHonerMarks() -> Completable {
        Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(GameLoadingError.unknownError))
                return Disposables.create()
            }

            self.gameLoadingService.createHonerMarkDeck()
                .subscribe(
                    onSuccess: { honerMarks in
                        self.honerMarks = honerMarks
                        self.updateProgress(
                            message: "Honer marks configured successfully.",
                            progress: 0.9)
                        completable(.completed)
                    },
                    onFailure: { error in
                        self.handleError(error)
                        completable(.error(error))
                    }
                )
                .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    private func playerRoundStateInitial(players: [Player]) -> Completable {
        validateRoundStateSetup(players: players)
            .andThen(assignRoundStates(players: players))
    }

    private func validateRoundStateSetup(players: [Player]) -> Completable {
        Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(GameLoadingError.unknownError))
                return Disposables.create()
            }

            guard self.factionCards.count == players.count else {
                completable(
                    .error(
                        GameLoadingError.invalidData(
                            NSError(
                                domain: "", code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Faction cards do not match player count."
                                ])
                        )))
                return Disposables.create()
            }

            guard
                players.allSatisfy({
                    self.playerCards[$0.name]?.count ?? 0 >= 3
                })
            else {
                completable(
                    .error(
                        GameLoadingError.invalidData(
                            NSError(
                                domain: "", code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Not all players have enough cards for the round."
                                ])
                        )))
                return Disposables.create()
            }

            completable(.completed)
            return Disposables.create()
        }
    }

    private func assignRoundStates(players: [Player]) -> Completable {
        Completable.zip(
            players.map { self.assignRoundStateToPlayer(player: $0) }
        )
    }

    private func assignRoundStateToPlayer(player: Player) -> Completable {
        Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(GameLoadingError.unknownError))
                return Disposables.create()
            }

            guard !self.factionCards.isEmpty else {
                completable(
                    .error(
                        GameLoadingError.invalidData(
                            NSError(
                                domain: "", code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "No more faction cards available."
                                ])
                        )))
                return Disposables.create()
            }

            let factionCard = self.factionCards.removeFirst()

            guard let handCards = self.playerCards[player.name]?.prefix(3)
            else {
                completable(
                    .error(
                        GameLoadingError.invalidData(
                            NSError(
                                domain: "", code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Player \(player.name) does not have enough cards."
                                ])
                        )))
                return Disposables.create()
            }

            let handCardIDs = handCards.map { $0.id ?? "" }

            let roundState = RoundState(
                faction: factionCard.name,
                isFactionRevealed: false,
                currentHand: handCardIDs,
                isAlive: true
            )

            self.gameLoadingService.addPlayerRoundState(
                roomID: roomID, playerName: player.name,
                playerRoundState: roundState
            )
            .subscribe(
                onCompleted: {
                    completable(.completed)
                },
                onError: { error in
                    self.handleError(error)
                    completable(.error(error))
                }
            )
            .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    private func handleError(_ error: Error) {
        let appError: AppError

        if let gameError = error as? GameLoadingError {
            switch gameError {
            case .unknownError:
                appError = AppError(
                    message: "An unknown error occurred during game loading.",
                    underlyingError: error, navigateTo: nil)
            case .invalidData(let invalidDataError):
                appError = AppError(
                    message:
                        "Invalid data: \(invalidDataError.localizedDescription)",
                    underlyingError: error, navigateTo: nil)
            case .documentNotFound:
                appError = AppError(
                    message: "The requested document was not found.",
                    underlyingError: error, navigateTo: nil)
            case .readFailed(let readError):
                appError = AppError(
                    message:
                        "Failed to read data: \(readError.localizedDescription)",
                    underlyingError: error, navigateTo: nil)
            case .writeFailed(let writeError):
                appError = AppError(
                    message:
                        "Failed to write data: \(writeError.localizedDescription)",
                    underlyingError: error, navigateTo: nil)
            case .deleteFailed(let deleteError):
                appError = AppError(
                    message:
                        "Failed to delete data: \(deleteError.localizedDescription)",
                    underlyingError: error, navigateTo: nil)
            case .updateFailed(let updateError):
                appError = AppError(
                    message:
                        "Failed to update data: \(updateError.localizedDescription)",
                    underlyingError: error, navigateTo: nil)
            case .listenerFailed(let listenerError):
                appError = AppError(
                    message:
                        "Failed to listen for changes: \(listenerError.localizedDescription)",
                    underlyingError: error, navigateTo: nil)
            }
        } else {
            appError = AppError(
                message:
                    "An unexpected error occurred: \(error.localizedDescription)",
                underlyingError: error, navigateTo: nil)
        }

        publish(.error(appError))
    }
}
