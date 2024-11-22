import RxSwift

extension PrimitiveSequence where Trait == SingleTrait {
    func value() async throws -> Element {
        try await withCheckedThrowingContinuation { continuation in
            _ = self.subscribe(
                onSuccess: { element in
                    continuation.resume(returning: element)
                },
                onFailure: { error in
                    continuation.resume(throwing: error)
                }
            )
        }
    }
}
