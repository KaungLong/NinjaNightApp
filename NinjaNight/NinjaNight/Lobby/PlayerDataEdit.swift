import Foundation
import RxSwift
import UIKit

class PlayerDataEdit: ComposeObservableObject<PlayerDataEdit.Event> {
    enum Event {
        case saveSucceeded
    }

    @Inject private var playerDataService: PlayerDataServiceProtocol
    @Inject private var loadingManager: LoadingManager
    private let disposeBag = DisposeBag()

    @Published var playerName: String = ""
    @Published var playerEmail: String = ""
    @Published var playerAvatar: UIImage?
    @Published var playerUid: String = ""

    func loadPlayerData() {
        loadingManager.isLoading = true
        playerDataService.loadPlayerData()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [unowned self] profile in
                    playerName = profile.name
                    playerEmail = profile.email
                    playerUid = profile.uid
                    if let avatarURL = profile.avatar {
                        loadAvatar(from: avatarURL)
                    }
                },
                onFailure: { [unowned self] error in
                    handleError(error)
                },
                onDisposed: { [unowned self] in
                    loadingManager.isLoading = false
                }
            )
            .disposed(by: disposeBag)
    }

    private func loadAvatar(from url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.playerAvatar = image
                }
            }
        }
    }

    func savePlayerName() {
        guard !playerName.isEmpty else {
            let error = AppError(message: "Name cannot be empty", underlyingError: nil, navigateTo: nil)
            handleError(error)
            return
        }
        loadingManager.isLoading = true
        playerDataService.updatePlayerName(playerName)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onCompleted: { [unowned self] in
                    publish(.event(.saveSucceeded))
                },
                onError: { [unowned self] error in
                    handleError(error)
                },
                onDisposed: { [unowned self] in
                    loadingManager.isLoading = false
                }
            )
            .disposed(by: disposeBag)
    }

    private func handleError(_ error: Error) {
        let appError: AppError

        if let serviceError = error as? PlayerDataServiceError {
            switch serviceError {
            case .userNotFound:
                appError = AppError(message: "User not found.", underlyingError: error, navigateTo: nil)
            case .invalidData:
                appError = AppError(message: "Invalid data provided.", underlyingError: error, navigateTo: nil)
            case .authError(let authError):
                appError = AppError(message: "Authentication error: \(authError.localizedDescription)", underlyingError: error, navigateTo: nil)
            case .unknown:
                appError = AppError(message: "An unknown error occurred.", underlyingError: error, navigateTo: nil)
            }
        } else {
            appError = AppError(message: "An unexpected error occurred: \(error.localizedDescription)", underlyingError: error, navigateTo: nil)
        }

        publish(.error(appError))
    }
}

