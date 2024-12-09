import SwiftUI

enum Pages: Hashable {
    case login
    case lobby
    case createdRoom
    case prepareRoom(roomInvitationCode: String)
    case roomList
    case playerDataEdit
    case gameLoading(roomID: String)
    case game(roomID: String)
}

enum GameMainPage: Hashable {
    case showFaction
}

class NavigationPathManager: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigate(to page: Pages) {
        path.append(page)
    }

    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func setRoot(to page: Pages) {
        path = NavigationPath()
        path.append(page)
    }
}
