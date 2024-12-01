import Foundation
import FirebaseFirestore
import RxSwift

enum RoomPrepareError: LocalizedError {
    case unknownError
    case roomFull
    case firebaseError(Error)
    case readFailed(Error)
    case writeFailed(Error)
    case deleteFailed(Error)
    case updateFailed(Error)
    case dataDecodingError(Error)
    case roomNotFound
    case playerNotFound
    case invalidData(Error)

    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred while preparing the room."
        case .roomFull:
            return "The room is full."
        case .firebaseError(let error):
            return "Firebase error: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read data: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to write data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        case .dataDecodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .roomNotFound:
            return "The room was not found."
        case .playerNotFound:
            return "The player was not found."
        case .invalidData(let error):
            return "Invalid data: \(error.localizedDescription)"
        }
    }
}

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
        )
        .flatMap { (rooms: [Room]) -> Single<Room> in
            guard let room = rooms.first else {
                return Single.error(RoomPrepareError.roomNotFound)
            }
        
            return self.fetchPlayerList(roomID: room.id ?? "")
                .flatMap { players -> Single<Room> in
                    var updatedRoom = room
                    updatedRoom.currentPlayerCount = players.count
                    updatedRoom.isFull = players.count >= room.maximumCapacity

                    if updatedRoom.isFull ?? false {
                        return Single.error(RoomPrepareError.roomFull)
                    }

                    return Single.just(updatedRoom)
                }
        }
        .catch { error in
            return Single.error(self.mapDatabaseErrorToRoomPrepareError(error))
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
            .catch { error in
                return Completable.error(self.mapDatabaseErrorToRoomPrepareError(error))
            }
        } catch {
            return Completable.error(RoomPrepareError.invalidData(error))
        }
    }

    func fetchPlayerList(roomID: String) -> Single<[Player]> {
        return adapter.queryCollection(collection: "RoomList/\(roomID)/RoomPlayerList")
            .catch { error in
                return Single.error(self.mapDatabaseErrorToRoomPrepareError(error))
            }
    }

    func listenToPlayerList(roomID: String) -> Observable<[Player]> {
        return adapter.listenToCollection(collection: "RoomList/\(roomID)/RoomPlayerList")
            .catch { error in
                return Observable.error(self.mapDatabaseErrorToRoomPrepareError(error))
            }
    }

    func listenToRoomUpdates(roomID: String) -> Observable<Room> {
        return adapter.listenToDocument(collection: "RoomList", documentID: roomID)
            .catch { error in
                return Observable.error(self.mapDatabaseErrorToRoomPrepareError(error))
            }
    }

    func updatePlayerReadyStatus(roomID: String, playerName: String, isReady: Bool) -> Completable {
        return adapter.updateDocument(
            collection: "RoomList/\(roomID)/RoomPlayerList",
            documentID: playerName,
            data: ["isReady": isReady]
        )
        .catch { error in
            return Completable.error(self.mapDatabaseErrorToRoomPrepareError(error))
        }
    }

    func updatePlayerHeartbeat(roomID: String, playerName: String, lastHeartbeat: Timestamp) -> Completable {
        return adapter.updateDocument(
            collection: "RoomList/\(roomID)/RoomPlayerList",
            documentID: playerName,
            data: ["lastHeartbeat": lastHeartbeat]
        )
        .catch { error in
            return Completable.error(self.mapDatabaseErrorToRoomPrepareError(error))
        }
    }

    func removePlayer(roomID: String, playerName: String) -> Completable {
        return adapter.deleteDocument(
            collection: "RoomList/\(roomID)/RoomPlayerList",
            documentID: playerName
        )
        .catch { error in
            return Completable.error(self.mapDatabaseErrorToRoomPrepareError(error))
        }
    }

    func deleteRoom(roomID: String) -> Completable {
        return adapter.deleteDocument(
            collection: "RoomList",
            documentID: roomID
        )
        .catch { error in
            return Completable.error(self.mapDatabaseErrorToRoomPrepareError(error))
        }
    }
    
    private func mapDatabaseErrorToRoomPrepareError(_ error: Error) -> Error {
        if let dbError = error as? DatabaseServiceError {
            switch dbError {
            case .readFailed(let firebaseError):
                return RoomPrepareError.readFailed(firebaseError)
            case .writeFailed(let firebaseError):
                return RoomPrepareError.writeFailed(firebaseError)
            case .deleteFailed(let firebaseError):
                return RoomPrepareError.deleteFailed(firebaseError)
            case .updateFailed(let firebaseError):
                return RoomPrepareError.updateFailed(firebaseError)
            case .dataDecodingError(let decodingError):
                return RoomPrepareError.dataDecodingError(decodingError)
            case .documentNotFound:
                return RoomPrepareError.roomNotFound
            case .listenerFailed(_):
                return RoomPrepareError.unknownError
            default:
                return RoomPrepareError.unknownError
            }
        } else {
            return RoomPrepareError.unknownError
        }
    }
}

