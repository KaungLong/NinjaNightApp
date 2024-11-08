import Swinject

@propertyWrapper
struct Inject<Service> {
    private var service: Service?

    init() {
        self.service = NinjaNightApp.container.resolve(Service.self)
        if service == nil {
            fatalError("Service of type \(Service.self) could not be resolved. Make sure it is registered in the container.")
        }
    }

    var wrappedValue: Service {
        guard let service = service else {
            fatalError("Service of type \(Service.self) could not be resolved.")
        }
        return service
    }
}
