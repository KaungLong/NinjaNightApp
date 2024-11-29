import Swinject
import SwinjectAutoregistration

class ServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(FirestoreAdapterProtocol.self, initializer: FirestoreAdapter.init)
        container.autoregister(FirebaseAuthAdapterProtocol.self, initializer: FirebaseAuthAdapter.init)
        container.autoregister(RoomPrepareProtocol.self, initializer: RoomPrepareService.init)
        container.autoregister(CreateRoomProtocol.self, initializer: CreateRoomService.init)
        container.autoregister(CodeAddingProtocol.self, initializer: CodeAddingService.init)
        container.autoregister(RootViewControllerProvider.self, initializer: DefaultRootViewControllerProvider.init)
        container.autoregister(RoomListServiceProtocol.self, initializer: RoomListService.init)
        container.autoregister(PlayerDataServiceProtocol.self, initializer: PlayerDataService.init)
        container.autoregister(AuthServiceProtocol.self, initializer: FirebaseAuthService.init)
        container.autoregister(UserDefaultsServiceProtocol.self, initializer: UserDefaultsService.init)
        
        container.register(LoadingManager.self) { _ in LoadingManager() }
               .inObjectScope(.container)
    }
}


