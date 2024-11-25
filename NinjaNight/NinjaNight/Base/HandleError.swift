import SwiftUI

typealias HandleError = (Error) -> Void

struct HandleErrorKey: EnvironmentKey {
    static let defaultValue: HandleError = { error in
        print("Unhandled error: \(error.localizedDescription)")
    }
}

extension EnvironmentValues {
    var handleError: HandleError {
        get { self[HandleErrorKey.self] }
        set { self[HandleErrorKey.self] = newValue }
    }
}

struct AppError: LocalizedError {
    let message: String
    let underlyingError: Error?
    let navigateTo: Pages?

    var errorDescription: String? {
        return message
    }
}
