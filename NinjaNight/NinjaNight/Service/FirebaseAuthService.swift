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
    case missingClientID
    case googleSignInFailed(Error)
    case missingIDToken
    case firebaseAuthFailed(Error)
    case unknownError

    var localizedDescription: String {
        switch self {
        case .missingClientID:
            return "Missing Google client ID"
        case .googleSignInFailed(let error):
            return "Google Sign-In failed: \(error.localizedDescription)"
        case .missingIDToken:
            return "Unable to retrieve Google ID token"
        case .firebaseAuthFailed(let error):
            return
                "Firebase authentication failed: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

protocol AuthServiceProtocol {
    var isSignedIn: Bool { get }
    func signInWithGoogle() -> Single<UserProfile>
    func signOut() -> Completable
    func getCurrentUserProfile() -> UserProfile?
    func getCurrentUserID() -> Single<String>
}

class FirebaseAuthService: AuthServiceProtocol {
    private let rootViewControllerProvider: RootViewControllerProvider
    private let userDefaultsService: UserDefaultsServiceProtocol

    init(
        rootViewControllerProvider: RootViewControllerProvider,
        userDefaultsService: UserDefaultsServiceProtocol
    ) {
        self.rootViewControllerProvider = rootViewControllerProvider
        self.userDefaultsService = userDefaultsService
    }

    var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }

    func getCurrentUserProfile() -> UserProfile? {
        guard let currentUser = Auth.auth().currentUser else {
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
                self.signInWithGoogleCredential(credential)
            }
            .do(onSuccess: { userProfile in
                let playerLoginData = PlayerLoginData(
                    userName: userProfile.name, userEmail: userProfile.email)
                self.userDefaultsService.setLoginState(playerLoginData)
                self.userDefaultsService.setIsSignedIn(true)
            })
    }

    func signOut() -> Completable {
        return Completable.create { completable in
            do {
                GIDSignIn.sharedInstance.signOut()
                try Auth.auth().signOut()
                
                self.userDefaultsService.clearLoginState()
                self.userDefaultsService.setIsSignedIn(false)
                
                completable(.completed)
            } catch {
                completable(.error(AuthServiceError.firebaseAuthFailed(error)))
            }
            return Disposables.create()
        }
    }

    func getCurrentUserID() -> Single<String> {
        return Single.create { single in
            if let uid = Auth.auth().currentUser?.uid {
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

    private func signInWithGoogleCredential(_ credential: AuthCredential)
        -> Single<UserProfile>
    {
        return Single.create { single in
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    single(.failure(AuthServiceError.firebaseAuthFailed(error)))
                    return
                }

                let userProfile = UserProfile(
                    name: authResult?.user.displayName ?? "No Name",
                    email: authResult?.user.email ?? "No Email"
                )

                single(.success(userProfile))
            }

            return Disposables.create()
        }
    }
}
