import Foundation
import RxSwift

struct PlayerProfile {
    var name: String
    var email: String
    var avatar: URL?
    var uid: String
}

enum PlayerDataServiceError: Error {
    case userNotFound
    case invalidData
    case authError(AuthAdapterError)
    case unknown
    var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "User not found."
        case .invalidData:
            return "Invalid data provided."
        case .authError(let authError):
            return "Authentication error: \(authError.localizedDescription)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

extension PlayerDataService {
    private func mapAuthError(_ error: Error) -> PlayerDataServiceError {
        if let authError = error as? AuthAdapterError {
            return .authError(authError)
        }
        return .unknown
    }
}

protocol PlayerDataServiceProtocol {
    func loadPlayerData() -> Single<PlayerProfile>
    func updatePlayerName(_ name: String) -> Completable
}

class PlayerDataService: PlayerDataServiceProtocol {
    private let authAdapter: FirebaseAuthAdapterProtocol

    init(authAdapter: FirebaseAuthAdapterProtocol) {
        self.authAdapter = authAdapter
    }

    func loadPlayerData() -> Single<PlayerProfile> {
        return Single.create { single in
            guard let currentUser = self.authAdapter.getCurrentUser() else {
                single(.failure(PlayerDataServiceError.userNotFound))
                return Disposables.create()
            }

            let userProfile = PlayerProfile(
                name: currentUser.displayName ?? "No Name",
                email: currentUser.email ?? "No Email",
                avatar: currentUser.photoURL,
                uid: currentUser.uid
            )
            single(.success(userProfile))
            return Disposables.create()
        }
    }

    func updatePlayerName(_ name: String) -> Completable {
        return Completable.create { completable in
            guard let currentUser = self.authAdapter.getCurrentUser() else {
                completable(.error(PlayerDataServiceError.userNotFound))
                return Disposables.create()
            }

            let changeRequest = currentUser.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { error in
                if let error = error {
                    completable(.error(self.mapAuthError(error)))
                } else {
                    completable(.completed)
                }
            }
            return Disposables.create()
        }
    }
}
