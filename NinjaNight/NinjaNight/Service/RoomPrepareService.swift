import Foundation
import FirebaseFirestore
import RxSwift

protocol RoomPrepareProtocol {
    func fetchRoom(invitationCode: String) -> Single<Room>
    func joinRoom(roomID: String, player: Player) -> Completable
    func fetchPlayerList(roomID: String) -> Single<[Player]>
    func listenToPlayerList(roomID: String) -> Observable<[Player]>
    func listenToRoomUpdates(roomID: String) -> Observable<Room>
    func updatePlayerReadyStatus(roomID: String, playerName: String, isReady: Bool) -> Completable
    func updatePlayerHeartbeat(roomID: String, playerName: String, lastHeartbeat: Timestamp) -> Completable
    func removePlayer(roomID: String, playerName: String) -> Completable
    func deleteRoom(roomID: String) -> Completable
}

class RoomPrepareService: RoomPrepareProtocol {
    private let adapter: FirestoreAdapterProtocol

    init(adapter: FirestoreAdapterProtocol) {
        self.adapter = adapter
    }

    func fetchRoom(invitationCode: String) -> Single<Room> {
        return adapter.queryDocuments(
            collection: "RoomList",
            field: "roomInvitationCode",
            value: invitationCode
        ).flatMap { (rooms: [Room]) in
            if let room = rooms.first {
                return Single.just(room)
            } else {
                return Single.error(DatabaseServiceError.noDataFound)
            }
        }
    }

    func joinRoom(roomID: String, player: Player) -> Completable {
        do {
            let data = try Firestore.Encoder().encode(player)
            return adapter.addDocument(
                collection: "RoomList/\(roomID)/RoomPlayerList",
                documentID: player.name,
                data: data
            )
        } catch {
            return Completable.error(DatabaseServiceError.writeFailed(error))
        }
    }

    func fetchPlayerList(roomID: String) -> Single<[Player]> {
        return adapter.queryCollection(collection: "RoomList/\(roomID)/RoomPlayerList")
    }

    func listenToPlayerList(roomID: String) -> Observable<[Player]> {
        return adapter.listenToCollection(collection: "RoomList/\(roomID)/RoomPlayerList")
    }

    func listenToRoomUpdates(roomID: String) -> Observable<Room> {
        return adapter.listenToDocument(collection: "RoomList", documentID: roomID)
    }

    func updatePlayerReadyStatus(roomID: String, playerName: String, isReady: Bool) -> Completable {
        return adapter.updateDocument(
            collection: "RoomList/\(roomID)/RoomPlayerList",
            documentID: playerName,
            data: ["isReady": isReady]
        )
    }

    func updatePlayerHeartbeat(roomID: String, playerName: String, lastHeartbeat: Timestamp) -> Completable {
        return adapter.updateDocument(
            collection: "RoomList/\(roomID)/RoomPlayerList",
            documentID: playerName,
            data: ["lastHeartbeat": lastHeartbeat]
        )
    }

    func removePlayer(roomID: String, playerName: String) -> Completable {
        return adapter.deleteDocument(
            collection: "RoomList/\(roomID)/RoomPlayerList",
            documentID: playerName
        )
    }

    func deleteRoom(roomID: String) -> Completable {
        return adapter.deleteDocument(
            collection: "RoomList",
            documentID: roomID
        )
    }
}
