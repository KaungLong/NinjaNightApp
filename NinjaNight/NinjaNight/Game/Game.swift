import RxCombine
import RxSwift
import SwiftUI

class Game: ComposeObservableObject<Game.Event> {
    @Published var gameMainActionState: GameMainActionState = .showFaction
    @Published var currentPhase: GameStage = .draft
    @Published var gameRound: Int = 0
    @Published var playerFaction: String = ""
    @Published var selectedCardID: String? = nil
    @Published var seletedCards: [Card] = []
    @Published var handCards: [CardUI] = []

    @Published var actionHint: String = "測試"
    @Published var totalSeconds: Double = 0.0
    @Published var remainingSeconds: Double = 0.0

    var roomID: String = ""
    
    @Inject private var cardService: CardServiceProtocol
    @Inject private var gameService: GameServiceProtocol
    @Inject private var userDefaultsService: UserDefaultsServiceProtocol
    private let disposeBag = DisposeBag()
    private var countdownDisposable: Disposable?

    init(roomID: String) {
        self.roomID = roomID
        super.init()
        observeEvents()
    }

    enum Event {
        case chooseCardStep1
        case chooseCardStep2
    }

    func roundStart() {
        updateRoomInfo()
            .andThen(getPlayerRoundState())
            .subscribe(
                onCompleted: {
                    print("Round started successfully")
                    self.showFaction()
                },
                onError: { error in
                    print("Failed to start round: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }

    func updateRoomInfo() -> Completable {
        return Completable.create { completable in
            self.gameService.fetchRoom(roomID: self.roomID)
                .subscribe { room in
                    self.currentPhase = room.currentPhase
                    self.gameRound = room.gameRound
                    completable(.completed)
                } onFailure: { error in
                    self.handleError(error: error)
                    completable(.error(error))
                }
                .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    func getPlayerRoundState() -> Completable {
        return Completable.create { completable in
            let playerName =
                self.userDefaultsService.getLoginState()?.userName ?? ""

            self.gameService.fetchPlayerRoundState(
                roomID: self.roomID,
                playerName: playerName,
                gameRound: "Round_\(self.gameRound)"
            )
            .flatMapCompletable { roundState in
                self.playerFaction = roundState.faction
                return self.fetchSelectedCards(cardIDs: roundState.currentHand)
            }
            .subscribe(
                onCompleted: {
                    completable(.completed)
                },
                onError: { error in
                    self.handleError(error: error)
                    completable(.error(error))
                }
            )
            .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    private func fetchSelectedCards(cardIDs: [String]) -> Completable {
        let cardFetches = cardIDs.map { id in
            self.cardService.fetchCardByID(id)
        }

        return Single.zip(cardFetches)
            .do(onSuccess: { cards in
                self.seletedCards = cards
            })
            .asCompletable()
    }

    func showFaction() {
        startCountdown(
            actionHint: "確認本回合所屬陣營",
            totalSeconds: 5,
            endEvent: .chooseCardStep1)
    }
    
    func chooseCardStep1() {
        startCountdown(
            actionHint: "選擇一張卡牌",
            totalSeconds: 10,
            endEvent: .chooseCardStep2)
    }
    
    func chooseCardStep2() {
        print("chooseCardStep2")
    }

    func startCountdown(
        actionHint: String, totalSeconds: Double, endEvent: Game.Event
    ) {
        self.actionHint = actionHint
        self.totalSeconds = totalSeconds
        self.remainingSeconds = totalSeconds

        countdownDisposable?.dispose()

        countdownDisposable = Observable<Int>.interval(
            .seconds(1), scheduler: MainScheduler.instance
        )
        .take(Int(totalSeconds) + 1)
        .subscribe(
            onNext: { [weak self] tick in
                guard let self = self else { return }
                self.remainingSeconds = self.totalSeconds - Double(tick)
            },
            onCompleted: { [weak self] in
                self?.publish(.event(endEvent))
            })

        countdownDisposable?.disposed(by: disposeBag)
    }

    private func observeEvents() {
        eventPublisher
            .asObservable()
            .subscribe(onNext: { [weak self] event in
                switch event {
                case .event(let customEvent):
                    self?.handleCustomEvent(customEvent)
                case .error:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    private func handleCustomEvent(_ event: Game.Event) {
        switch event {
        case .chooseCardStep1:
            chooseCardStep1()
        case .chooseCardStep2:
            chooseCardStep2()
        }
    }

    func stopCountdown() {
        countdownDisposable?.dispose()
    }

    private func handleError(error: Error) {
        print("等待handleError: \(error)")
    }

}
