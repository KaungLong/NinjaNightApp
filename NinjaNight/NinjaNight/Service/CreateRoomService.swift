import Foundation
import RxSwift

protocol CreateRoomProtocol {
    func createRoom(with room: Room) -> Completable
}

class CreateRoomService: CreateRoomProtocol {
    private let adapter: FirestoreAdapterProtocol
    
    init(adapter: FirestoreAdapterProtocol) {
        self.adapter = adapter
    }
    
    func createRoom(with room: Room) -> Completable {
        let roomData = room.toDictionary()
        return adapter.addDocument(collection: "RoomList", data: roomData)
    }
}
