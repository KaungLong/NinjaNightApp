import UIKit

protocol RootViewControllerProvider {
    func getRootViewController() -> UIViewController
}

class DefaultRootViewControllerProvider: RootViewControllerProvider {
    func getRootViewController() -> UIViewController {
        guard
            let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = screen.windows.first?.rootViewController
        else {
            fatalError("Unable to get rootViewController")
        }
        return root
    }
}
