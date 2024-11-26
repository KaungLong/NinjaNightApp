import Firebase
import FirebaseAuth
import Foundation
import GoogleSignIn
import RxSwift

struct UserProfile {
    let name: String
    let email: String
}

enum AuthServiceError: Error {
    case unknownError
    case invalidCredential
    case userNotFound
    case networkError
    case missingClientID
    case googleSignInFailed(Error)
    case missingIDToken
    case signOutFailed
    case firebaseError(Error)
}

protocol AuthServiceProtocol {
    var isSignedIn: Bool { get }
    func signInWithGoogle() -> Single<UserProfile>
    func signOut() -> Completable
    func getCurrentUserProfile() -> UserProfile?
    func getCurrentUserID() -> Single<String>
}

class FirebaseAuthService: AuthServiceProtocol {
    private let authAdapter: FirebaseAuthAdapterProtocol
    private let rootViewControllerProvider: RootViewControllerProvider
    private let userDefaultsService: UserDefaultsServiceProtocol

    init(
        authAdapter: FirebaseAuthAdapterProtocol,
        rootViewControllerProvider: RootViewControllerProvider,
        userDefaultsService: UserDefaultsServiceProtocol
    ) {
        self.authAdapter = authAdapter
        self.rootViewControllerProvider = rootViewControllerProvider
        self.userDefaultsService = userDefaultsService
    }

    var isSignedIn: Bool {
        return authAdapter.getCurrentUser() != nil
    }

    func getCurrentUserProfile() -> UserProfile? {
        guard let currentUser = authAdapter.getCurrentUser() else {
            return nil
        }

        return UserProfile(
            name: currentUser.displayName ?? "No Name",
            email: currentUser.email ?? "No Email"
        )
    }

    func signInWithGoogle() -> Single<UserProfile> {
        return configureGoogleSignIn()
            .flatMap { credential in
                self.authAdapter.signInWithCredential(credential)
                    .catch { error in
                        return Single.error(self.mapAuthAdapterError(error))
                    }
            }
            .map { authResult in
                let userProfile = UserProfile(
                    name: authResult.user.displayName ?? "No Name",
                    email: authResult.user.email ?? "No Email"
                )
                return userProfile
            }
            .do(onSuccess: { userProfile in
                let playerLoginData = PlayerLoginData(
                    userName: userProfile.name,
                    userEmail: userProfile.email
                )
                self.userDefaultsService.setLoginState(playerLoginData)
                self.userDefaultsService.setIsSignedIn(true)
            })
    }
    
    func signOut() -> Completable {
        return authAdapter.signOut()
            .catch { error in
                return Completable.error(self.mapAuthAdapterError(error))
            }
            .do(onCompleted: {
                self.userDefaultsService.clearLoginState()
                self.userDefaultsService.setIsSignedIn(false)
            })
    }

    func getCurrentUserID() -> Single<String> {
        return Single.create { single in
            if let uid = self.authAdapter.getCurrentUser()?.uid {
                single(.success(uid))
            } else {
                single(.failure(AuthServiceError.unknownError))
            }
            return Disposables.create()
        }
    }

    private func configureGoogleSignIn() -> Single<AuthCredential> {
        return Single.create { [unowned self] single in
            guard let clientID = getClientID() else {
                single(.failure(AuthServiceError.missingClientID))
                return Disposables.create()
            }

            setupGoogleSignInConfiguration(with: clientID)

            performGoogleSignIn { result in
                switch result {
                case .success(let credential):
                    single(.success(credential))
                case .failure(let error):
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    private func getClientID() -> String? {
        return FirebaseApp.app()?.options.clientID
    }

    private func setupGoogleSignInConfiguration(with clientID: String) {
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }

    private func performGoogleSignIn(
        completion: @escaping (Result<AuthCredential, AuthServiceError>) -> Void
    ) {
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewControllerProvider.getRootViewController()
        ) { result, error in
            if let error = error {
                completion(.failure(.googleSignInFailed(error)))
                return
            }

            guard let credential = self.createCredential(from: result) else {
                completion(.failure(.missingIDToken))
                return
            }

            completion(.success(credential))
        }
    }

    private func createCredential(from result: GIDSignInResult?)
        -> AuthCredential?
    {
        guard let user = result?.user,
            let idToken = user.idToken?.tokenString
        else { return nil }

        let accessToken = user.accessToken.tokenString

        return GoogleAuthProvider.credential(
            withIDToken: idToken, accessToken: accessToken)
    }
    
    private func mapAuthAdapterError(_ error: Error) -> AuthServiceError {
         if let adapterError = error as? AuthAdapterError {
             switch adapterError {
             case .invalidCredential:
                 return .invalidCredential
             case .userNotFound:
                 return .userNotFound
             case .networkError:
                 return .networkError
             case .unknownError:
                 return .unknownError
             case .firebaseError(let firebaseError):
                 return .firebaseError(firebaseError)
             }
         } else {
             return .unknownError
         }
     }
}
