import SwiftUI
import Combine

enum PublishEvent<T> {
    case error(Error)
    case event(T)
}

protocol EventConsumer: ObservableObject {
    associatedtype CustomEvent
    var eventPublisher: AnyPublisher<PublishEvent<CustomEvent>, Never> { get }
}

class ComposeObservableObject<T>: ObservableObject, EventConsumer {
    typealias CustomEvent = T
    private let _publisher = PassthroughSubject<PublishEvent<T>, Never>()
    var eventPublisher: AnyPublisher<PublishEvent<T>, Never> {
        _publisher.eraseToAnyPublisher()
    }
    
    func publish(_ event: PublishEvent<T>) {
        _publisher.send(event)
    }
}

extension View {
    func onConsume<Consumer: EventConsumer>(
        _ errorHandler: @escaping HandleError,
        _ consumer: Consumer,
        _ consume: @escaping (Consumer.CustomEvent) -> Void
    ) -> some View {
        return onReceive(consumer.eventPublisher) { event in
            print("Received event: \(event)")
            switch event {
            case .error(let err):
                errorHandler(err)
            case .event(let customEvent):
                consume(customEvent)
            }
        }
    }
}
