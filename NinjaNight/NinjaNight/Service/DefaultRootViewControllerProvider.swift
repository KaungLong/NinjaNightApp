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

//TODO: 想一下這邊需不需要留下，該Provider是否有必要
