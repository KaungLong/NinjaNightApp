import Combine

class BaseViewModel<Event>: ObservableObject {
    @Published var event: Event?
    @Published var error: Error?

    func sendEvent(_ event: Event) {
        self.event = event
    }

    func sendError(_ error: Error) {
        self.error = error
    }
}
