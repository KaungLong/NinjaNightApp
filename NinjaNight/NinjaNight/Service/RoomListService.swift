import Foundation
import FirebaseFirestore
import RxSwift

protocol RoomListServiceProtocol {
    func fetchRoomsWithPlayerCounts() -> Single<[Room]>
}

class RoomListService: RoomListServiceProtocol {
    private let firestoreAdapter: FirestoreAdapterProtocol
    
    init(firestoreAdapter: FirestoreAdapterProtocol) {
        self.firestoreAdapter = firestoreAdapter
    }
    
    private func fetchAllRooms() -> Single<[Room]> {
        return firestoreAdapter.queryCollection(collection: "RoomList")
    }
    
    private func fetchPlayers(forRoomID roomID: String) -> Single<[Player]> {
        return firestoreAdapter.queryCollection(collection: "RoomList/\(roomID)/player")
    }
    
    func fetchRoomsWithPlayerCounts() -> Single<[Room]> {
        return fetchAllRooms().flatMap { rooms in
            let roomObservables = rooms.map { room in
                self.fetchPlayers(forRoomID: room.id ?? "")
                    .map { players in
                        var updatedRoom = room
                        updatedRoom.currentPlayerCount = players.count
                        updatedRoom.isFull = players.count == room.roomCapacity
                        return updatedRoom
                    }
            }
            return Single.zip(roomObservables)
        }
    }
}
