import Foundation

struct PlayerLoginData: Codable {
    var userName: String
    var userEmail: String
}

protocol UserDefaultsServiceProtocol {
    func setLoginState(_ state: PlayerLoginData)
    func getLoginState() -> PlayerLoginData?
    func clearLoginState()
    func setIsSignedIn(_ isSignedIn: Bool)
    func getIsSignedIn() -> Bool
}

class UserDefaultsService: UserDefaultsServiceProtocol {
    private let defaults: UserDefaults = .standard
    private let loginStateKey = "loginState"
    private let isSignedInKey = "isSignedIn"

    func setLoginState(_ state: PlayerLoginData) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: loginStateKey)
        } else {
            print("Failed to encode LoginState")
        }
    }

    func getLoginState() -> PlayerLoginData? {
        guard let data = defaults.data(forKey: loginStateKey) else { return nil }
        return try? JSONDecoder().decode(PlayerLoginData.self, from: data)
    }

    func clearLoginState() {
        defaults.removeObject(forKey: loginStateKey)
    }

    func setIsSignedIn(_ isSignedIn: Bool) {
        defaults.set(isSignedIn, forKey: isSignedInKey)
    }

    func getIsSignedIn() -> Bool {
        return defaults.bool(forKey: isSignedInKey)
    }
}
