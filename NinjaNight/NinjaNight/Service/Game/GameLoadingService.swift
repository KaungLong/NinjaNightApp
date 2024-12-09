import FirebaseFirestore
import RxSwift

enum GameLoadingError: LocalizedError {
    case unknownError
    case invalidData(Error)
    case documentNotFound
    case readFailed(Error)
    case writeFailed(Error)
    case deleteFailed(Error)
    case updateFailed(Error)
    case listenerFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred while game loading."
        case .invalidData(let error):
            return "Invalid data: \(error.localizedDescription)"
        case .documentNotFound:
            return "The requested document was not found."
        case .readFailed(let error):
            return "Failed to read data: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to write data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        case .listenerFailed(let error):
            return "Failed to listen for data changes: \(error.localizedDescription)"
        }
    }
}

protocol GameLoadingServiceProtocol {
    func fetchRoom(roomID: String) -> Single<Room> 
    func addPlayerRoundState(
        roomID: String, documentID: String, playerName: String, playerRoundState: RoundState
    ) -> Completable
    func fetchPlayers(roomID: String) -> Single<[Player]>
    func createRoundDeck(numberOfPlayers: Int, initialHandCards: Int) -> Single<[Card]>
    func createFactionDeck(numberOfPlayers: Int) -> Single<[Faction]>
    func createHonerMarkDeck() -> Single<[HonerMark]>
    func updateProgress(roomID: String, progress: Double, message: String) -> Completable
    func listenToRoom(roomID: String) -> Observable<Room>
    func updateGameStageAndGameRound(roomID: String, currentGameRound: Int, gameStage: GameStage) -> Completable
}

class GameLoadingService: GameLoadingServiceProtocol {
    private let adapter: FirestoreAdapterProtocol

    init(adapter: FirestoreAdapterProtocol) {
        self.adapter = adapter
    }
    
    func fetchRoom(roomID: String) -> Single<Room> {
        return adapter.fetchDocument(
            collection: "RoomList",
            documentID: roomID)
        .catch { error in
            return Single.error(
                self.mapDatabaseErrorGameLoadingError(error))
        }
    }

    func addPlayerRoundState(
        roomID: String, documentID: String, playerName: String, playerRoundState: RoundState
    ) -> Completable {
        do {
            let data = try Firestore.Encoder().encode(playerRoundState)
            return adapter.addDocument(
                collection:
                    "RoomList/\(roomID)/RoomPlayerList/\(playerName)/PlayerRoundStateList",
                documentID: documentID,
                data: data
            )
            .catch { error in
                return Completable.error(
                    self.mapDatabaseErrorGameLoadingError(error))
            }
        } catch {
            return Completable.error(GameLoadingError.invalidData(error))
        }
    }

    func fetchPlayers(roomID: String) -> Single<[Player]> {
        let collectionPath = "RoomList/\(roomID)/RoomPlayerList"
        return adapter.queryCollection(collection: collectionPath)
            .catch { error in
                return Single.error(
                    self.mapDatabaseErrorGameLoadingError(error))
            }
    }
    
    func createRoundDeck(numberOfPlayers: Int, initialHandCards: Int) -> Single<[Card]> {
        let requiredCardCount = numberOfPlayers * initialHandCards
        let collectionPath = "DeckSetting"
        
        return adapter.queryCollection(collection: collectionPath)
            .flatMap { (allCards: [Card]) -> Single<[Card]> in
                guard allCards.count >= requiredCardCount else {
                    return Single.error(GameLoadingError.invalidData(
                        NSError(domain: "", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Not enough cards in DeckSetting to fulfill the request."
                        ])
                    ))
                }
                
                let shuffledCards = allCards.shuffled()
                let selectedCards = Array(shuffledCards.prefix(requiredCardCount))
                return Single.just(selectedCards)
            }
            .catch { error in
                return Single.error(self.mapDatabaseErrorGameLoadingError(error))
            }
    }
    
    func createFactionDeck(numberOfPlayers: Int) -> Single<[Faction]> {
        return Single.create { single in
            guard numberOfPlayers > 0 else {
                single(.failure(GameLoadingError.invalidData(
                    NSError(domain: "", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Number of players must be greater than 0."
                    ])
                )))
                return Disposables.create()
            }
            
            var factions: [Faction] = []
            
            if numberOfPlayers == 1 {
                factions.append(.ronin)
                //TODO: 理論上不會出現numberOfPlayers小於5的情況，需要重新思考
            } else if numberOfPlayers % 2 == 0 {
                let half = numberOfPlayers / 2
                factions.append(contentsOf: (1...half).map { .crane($0) })
                factions.append(contentsOf: (1...half).map { .lotus($0) })
            } else {
                factions.append(.ronin)
                let remaining = numberOfPlayers - 1
                let half = remaining / 2
                if half > 0 {
                    factions.append(contentsOf: (1...half).map { .crane($0) })
                    factions.append(contentsOf: (1...half).map { .lotus($0) })
                }
            }

            factions.shuffle()
            
            single(.success(factions))
            return Disposables.create()
        }
    }
    
    func createHonerMarkDeck() -> Single<[HonerMark]> {
        return Single.create { single in
            let twoPointMarks = Array(repeating: HonerMark(score: 2), count: 11)
            let threePointMarks = Array(repeating: HonerMark(score: 3), count: 13)
            let fourPointMarks = Array(repeating: HonerMark(score: 4), count: 11)
            
            var honerMarks = twoPointMarks + threePointMarks + fourPointMarks
            
            honerMarks.shuffle()
            
            single(.success(honerMarks))
            return Disposables.create()
        }
    }

    private func mapDatabaseErrorGameLoadingError(_ error: Error) -> Error {
        if let dbError = error as? DatabaseServiceError {
            switch dbError {
            case .readFailed(let firebaseError):
                return GameLoadingError.readFailed(firebaseError)
            case .writeFailed(let firebaseError):
                return GameLoadingError.writeFailed(firebaseError)
            case .deleteFailed(let firebaseError):
                return GameLoadingError.deleteFailed(firebaseError)
            case .updateFailed(let firebaseError):
                return GameLoadingError.updateFailed(firebaseError)
            case .dataDecodingError(let decodingError):
                return GameLoadingError.invalidData(decodingError)
            case .documentNotFound:
                return GameLoadingError.documentNotFound
            case .listenerFailed(let listenerError):
                return GameLoadingError.listenerFailed(listenerError)
            default:
                return GameLoadingError.unknownError
            }
        } else {
            return GameLoadingError.unknownError
        }
    }
    
    func updateProgress(roomID: String, progress: Double, message: String) -> Completable {
        let updateData: [String: Any] = [
            "currentSettingProgress": progress,
            "loadingMessage": message
        ]
        
        return adapter.updateDocument(
            collection: "RoomList",
            documentID: roomID,
            data: updateData
        )
        .catch { error in
            return Completable.error(self.mapDatabaseErrorGameLoadingError(error))
        }
    }
    
    func updateGameStageAndGameRound(roomID: String, currentGameRound: Int, gameStage: GameStage) -> Completable {
        let updateData: [String: Any] = [
            "gameRound": currentGameRound,
            "currentPhase": gameStage.rawValue
        ]
        
        return adapter.updateDocument(
            collection: "RoomList",
            documentID: roomID,
            data: updateData
        )
        .catch { error in
            return Completable.error(self.mapDatabaseErrorGameLoadingError(error))
        }
    }
    
    func listenToRoom(roomID: String) -> Observable<Room> {
        return adapter.listenToDocument(collection: "RoomList", documentID: roomID)
            .catch { error in
                Observable.error(self.mapDatabaseErrorGameLoadingError(error))
            }
    }
}

enum Faction: Equatable {
    case crane(Int)
    case lotus(Int)
    case ronin

    var name: String {
        switch self {
        case .crane(let number):
            return "crane\(number)"
        case .lotus(let number):
            return "lotus\(number)"
        case .ronin:
            return "ronin"
        }
    }
}

struct HonerMark {
    var score: Int
}
