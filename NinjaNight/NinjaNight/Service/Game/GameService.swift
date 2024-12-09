import FirebaseFirestore
import RxSwift


protocol GameServiceProtocol {
    func fetchRoom(roomID: String) -> Single<Room>
    func fetchPlayerRoundState(roomID: String, playerName: String, gameRound: String) -> Single<RoundState>
}

class GameService: GameServiceProtocol {
    private let adapter: FirestoreAdapterProtocol
    
    init(adapter: FirestoreAdapterProtocol) {
        self.adapter = adapter
    }
    
    func fetchRoom(roomID: String) -> Single<Room> {
        adapter.fetchDocument(collection: "RoomList", documentID: roomID)
    }
    
    func fetchPlayerRoundState(roomID: String, playerName: String, gameRound: String) -> Single<RoundState> {
        adapter.fetchDocument(
            collection: "RoomList/\(roomID)/RoomPlayerList/\(playerName)/PlayerRoundStateList",
            documentID: gameRound
        )
    }
    
}
    
