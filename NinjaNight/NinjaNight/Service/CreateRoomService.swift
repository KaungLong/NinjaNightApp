import Foundation
import RxSwift

enum CreateRoomError: LocalizedError {
    case unknownError
    case firebaseError(Error)
    case writeFailed(Error)
    case invalidRoomData

    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred while creating the room."
        case .firebaseError(let error):
            return "Firebase error: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to create the room: \(error.localizedDescription)"
        case .invalidRoomData:
            return "Invalid room data provided."
        }
    }
}

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
            .catch { error in
                if let dbError = error as? DatabaseServiceError {
                    switch dbError {
                    case .writeFailed(let firebaseError):
                        return .error(CreateRoomError.writeFailed(firebaseError))
                    case .firebaseError(let firebaseError):
                        return .error(CreateRoomError.firebaseError(firebaseError))
                    default:
                        return .error(CreateRoomError.unknownError)
                    }
                } else {
                    return .error(CreateRoomError.unknownError)
                }
            }
    }
}
