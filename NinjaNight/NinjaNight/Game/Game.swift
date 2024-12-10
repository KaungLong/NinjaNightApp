import RxSwift
import SwiftUI

class Game: ComposeObservableObject<Game.Event> {
    @Published var gameMainActionState: GameMainActionState = .showFaction
    @Published var currentPhase: GameStage = .draft
    @Published var gameRound: Int = 0
    @Published var playerFaction: String = ""
    
    var roomID: String = ""
    @Inject private var gameService: GameServiceProtocol
    @Inject private var userDefaultsService: UserDefaultsServiceProtocol
    private let disposeBag = DisposeBag()
    
    init(roomID: String) {
        self.roomID = roomID
    }

    enum Event {

    }
    
    func roundStart() {
        updateRoomInfo()
            .andThen(getPlayerRoundState())
            .subscribe(
                onCompleted: {
                    print("Round started successfully")
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
               let playerName = self.userDefaultsService.getLoginState()?.userName ?? ""
               self.gameService.fetchPlayerRoundState(roomID: self.roomID, playerName: playerName, gameRound: "Round_\(self.gameRound)")
                   .subscribe { roundState in
                       self.playerFaction = roundState.faction
                       completable(.completed)
                   } onFailure: { error in
                       self.handleError(error: error)
                       completable(.error(error))
                   }
                   .disposed(by: self.disposeBag)
               
               return Disposables.create()
           }
       }

    private func handleError(error: Error) {
        print("等待handleError: \(error)")
    }

}
