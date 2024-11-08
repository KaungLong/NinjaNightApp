import FirebaseCore
import SwiftUI
import GoogleSignIn
import Swinject

@main
struct NinjaNightApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    static let container = Container() 

    init() {
        let assembler = Assembler([ServiceAssembly()], container: NinjaNightApp.container)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}



