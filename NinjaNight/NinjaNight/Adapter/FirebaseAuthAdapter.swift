import GoogleSignIn
import FirebaseAuth
import Firebase
import RxSwift

enum AuthAdapterError: Error {
    case unknownError
    case firebaseError(Error)
    case invalidCredential
    case userNotFound
    case networkError
}

protocol FirebaseAuthAdapterProtocol {
    func signInWithCredential(_ credential: AuthCredential) -> Single<AuthDataResult>
    func signOut() -> Completable
    func getCurrentUser() -> User?
}

class FirebaseAuthAdapter: FirebaseAuthAdapterProtocol {
    func signInWithCredential(_ credential: AuthCredential) -> Single<AuthDataResult> {
        return Single.create { single in
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error as NSError? {
                    switch AuthErrorCode(rawValue: error.code) {
                    case .invalidCredential:
                        single(.failure(AuthAdapterError.invalidCredential))
                    case .userNotFound:
                        single(.failure(AuthAdapterError.userNotFound))
                    case .networkError:
                        single(.failure(AuthAdapterError.networkError))
                    default:
                        single(.failure(AuthAdapterError.firebaseError(error)))
                    }
                } else if let authResult = authResult {
                    single(.success(authResult))
                } else {
                    single(.failure(AuthAdapterError.unknownError))
                }
            }
            return Disposables.create()
        }
    }

    func signOut() -> Completable {
        return Completable.create { completable in
            do {
                try Auth.auth().signOut()
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            return Disposables.create()
        }
    }

    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
}
