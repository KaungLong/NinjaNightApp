import Foundation
import FirebaseFirestore
import RxSwift

enum RoomListServiceError: Error {
    case databaseError(DatabaseServiceError)
    case unknownError
}

extension RoomListServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .databaseError(let error):
            return error.localizedDescription
        case .unknownError:
            return NSLocalizedString("An unknown error occurred in RoomListService.", comment: "")
        }
    }
}

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
            .catch { self.mapErrorToRoomListServiceError($0) }
    }

    private func fetchPlayers(forRoomID roomID: String) -> Single<[Player]> {
        return firestoreAdapter.queryCollection(collection: "RoomList/\(roomID)/RoomPlayerList")
            .catch { self.mapErrorToRoomListServiceError($0) }
    }

    func fetchRoomsWithPlayerCounts() -> Single<[Room]> {
        return fetchAllRooms()
            .flatMap { rooms in
                let roomObservables = rooms.map { room in
                    self.fetchPlayers(forRoomID: room.id ?? "")
                        .map { players in
                            var updatedRoom = room
                            updatedRoom.currentPlayerCount = players.count
                            updatedRoom.isFull = players.count == room.maximumCapacity
                            return updatedRoom
                        }
                }
                return Single.zip(roomObservables)
            }
            .catch { self.mapErrorToRoomListServiceError($0) }
    }

    private func mapErrorToRoomListServiceError<T>(_ error: Error) -> Single<T> {
        if let databaseError = error as? DatabaseServiceError {
            return .error(RoomListServiceError.databaseError(databaseError))
        }
        return .error(RoomListServiceError.unknownError)
    }
}
