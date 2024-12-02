import Foundation
import RxSwift

enum CodeAddingError: LocalizedError {
    case unknownError
    case firebaseError(Error)
    case readFailed(Error)
    case roomNotFound

    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred while checking the room."
        case .firebaseError(let error):
            return "Firebase error: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read the room data: \(error.localizedDescription)"
        case .roomNotFound:
            return "The room with the provided invitation code does not exist."
        }
    }
}

protocol CodeAddingProtocol {
    func checkRoomExists(invitationCode: String) -> Single<Bool>
}

class CodeAddingService: CodeAddingProtocol {
    private let adapter: FirestoreAdapterProtocol

    init(adapter: FirestoreAdapterProtocol) {
        self.adapter = adapter
    }

    func checkRoomExists(invitationCode: String) -> Single<Bool> {
        return adapter.queryDocuments(
            collection: "RoomList",
            field: "roomInvitationCode",
            value: invitationCode
        )
        .map { (rooms: [Room]) in
            !rooms.isEmpty
        }
        .catch { error in
            if let dbError = error as? DatabaseServiceError {
                switch dbError {
                case .readFailed(let firebaseError):
                    return .error(CodeAddingError.readFailed(firebaseError))
                case .firebaseError(let firebaseError):
                    return .error(CodeAddingError.firebaseError(firebaseError))
                case .documentNotFound, .dataDecodingError:
                    return .error(CodeAddingError.roomNotFound)
                default:
                    return .error(CodeAddingError.unknownError)
                }
            } else {
                return .error(CodeAddingError.unknownError)
            }
        }
    }
}
