import Swinject
import SwinjectAutoregistration

class ServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(RootViewControllerProvider.self, initializer: DefaultRootViewControllerProvider.init)
        container.autoregister(DatabaseServiceProtocol.self, initializer: FirestoreDatabaseService.init)
        container.autoregister(AuthServiceProtocol.self, initializer: FirebaseAuthService.init)
        container.autoregister(UserDefaultsServiceProtocol.self, initializer: UserDefaultsService.init)
        
        container.register(LoadingManager.self) { _ in LoadingManager() }
               .inObjectScope(.container)
    }
}


