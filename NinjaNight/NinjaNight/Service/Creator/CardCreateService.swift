import RxSwift
import FirebaseFirestore

enum CardCreateError: LocalizedError {
    case unknownError
    case invalidData(Error)
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred while managing deck settings."
        case .invalidData(let error):
            return "Invalid card data: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to write card data: \(error.localizedDescription)"
        }
    }
}

protocol CardCreateServiceProtocol {
    func createCard(cardID: String, card: Card) -> Completable
}

class CardCreateService: CardCreateServiceProtocol {
    private let adapter: FirestoreAdapterProtocol

    init(adapter: FirestoreAdapterProtocol) {
        self.adapter = adapter
    }

    func createCard(cardID: String, card: Card) -> Completable {
        do {
            let data = try Firestore.Encoder().encode(card)
            return adapter.addDocument(
                collection: "DeckSetting",
                documentID: cardID,
                data: data
            )
            .catch { error in
                return Completable.error(self.mapDatabaseErrorDeckSettingError(error))
            }
        } catch {
            return Completable.error(CardCreateError.invalidData(error))
        }
    }

    private func mapDatabaseErrorDeckSettingError(_ error: Error) -> Error {
        if let dbError = error as? DatabaseServiceError {
            switch dbError {
            case .writeFailed(let firebaseError):
                return CardCreateError.writeFailed(firebaseError)
            case .dataDecodingError(let decodingError):
                return CardCreateError.invalidData(decodingError)
            default:
                return CardCreateError.unknownError
            }
        } else {
            return CardCreateError.unknownError
        }
    }
}
