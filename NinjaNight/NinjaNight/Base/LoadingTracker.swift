import RxSwift
import RxCocoa
import SwiftUI

class LoadingTracker {
    private let _loading = BehaviorRelay(value: false)

    var isLoading: Observable<Bool> {
        return _loading.asObservable()
    }

    func track<O: ObservableConvertibleType>(_ source: O) -> Observable<O.Element> {
        return Observable.create { [weak self] observer in
            self?._loading.accept(true)
            let subscription = source.asObservable()
                .subscribe { event in
                    if event.isStopEvent {
                        self?._loading.accept(false)
                    }
                    observer.on(event)
                }
            return Disposables.create {
                subscription.dispose()
            }
        }
    }

    func trackSingle<T>(_ source: Single<T>) -> Single<T> {
        return Single.create { [weak self] single in
            self?._loading.accept(true)
            let subscription = source.subscribe { event in
                self?._loading.accept(false)
                switch event {
                case .success(let element):
                    single(.success(element))
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create {
                subscription.dispose()
            }
        }
    }
}

extension ObservableConvertibleType {
    func trackLoading(_ loadingTracker: LoadingTracker) -> Observable<Element> {
        return loadingTracker.track(self)
    }
}

extension PrimitiveSequence where Trait == SingleTrait {
    func trackLoading(_ loadingTracker: LoadingTracker) -> Single<Element> {
        return loadingTracker.trackSingle(self)
    }
}



