import CoreData
import FirebaseFirestore
import RxSwift

enum CardError: LocalizedError {
    case unknownError
    case invalidData(Error)
    case writeFailed(Error)
    case cardNotFound(String)

    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred while managing deck settings."
        case .invalidData(let error):
            return "Invalid card data: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to write card data: \(error.localizedDescription)"
        case .cardNotFound(let name):
            return "Card with name '\(name)' not found."
        }
    }
}

protocol CardServiceProtocol {
    func createCard(cardID: String, card: Card) -> Completable
    func fetchCards() -> Single<[Card]>
    func fetchCardByName(_ name: String) -> Single<Card>
    func fetchAllCards() -> Single<[Card]>
}

class CardService: CardServiceProtocol {
    private let adapter: FirestoreAdapterProtocol
    private let viewContext: NSManagedObjectContext

    init(adapter: FirestoreAdapterProtocol) {
        self.adapter = adapter
        self.viewContext = PersistenceController.shared.viewContext
    }

    func fetchCards() -> Single<[Card]> {
        return adapter.queryCollection(collection: "DeckSetting")
            .do(onSuccess: { [weak self] cards in
                self?.saveCardsToCoreData(cards: cards)
            })
    }

    private func saveCardsToCoreData(cards: [Card]) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
            CardEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try viewContext.execute(deleteRequest)
        } catch {
            print("Failed to delete old cards: \(error)")
        }

        for card in cards {
            let cardEntity = CardEntity(context: viewContext)
            cardEntity.id = card.id
            cardEntity.cardName = card.cardName
            cardEntity.cardLevel = Int32(card.cardLevel)
            cardEntity.cardType = card.cardType.rawValue
            cardEntity.cardDetail = card.cardDetail
        }

        do {
            try viewContext.save()
            print("Cards saved to Core Data successfully.")
        } catch {
            print("Failed to save cards to Core Data: \(error)")
        }
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
                return Completable.error(
                    self.mapDatabaseErrorDeckSettingError(error))
            }
        } catch {
            return Completable.error(CardError.invalidData(error))
        }
    }

    func fetchCardByName(_ name: String) -> Single<Card> {
        return Single.create { single in
            let fetchRequest: NSFetchRequest<CardEntity> =
                CardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "cardName == %@", name)
            fetchRequest.fetchLimit = 1

            do {
                if let cardEntity = try self.viewContext.fetch(fetchRequest)
                    .first
                {
                    let card = Card(
                        id: cardEntity.id,
                        cardName: cardEntity.cardName ?? "",
                        cardLevel: Int(cardEntity.cardLevel),
                        cardType: CardType(rawValue: cardEntity.cardType ?? "")
                            ?? .special,
                        cardDetail: cardEntity.cardDetail ?? ""
                    )
                    single(.success(card))
                } else {
                    single(.failure(CardError.cardNotFound(name)))
                }
            } catch {
                single(.failure(error))
            }

            return Disposables.create()
        }
    }

    func fetchAllCards() -> Single<[Card]> {
        return Single.create { single in
            let fetchRequest: NSFetchRequest<CardEntity> =
                CardEntity.fetchRequest()

            do {
                let cardEntities = try self.viewContext.fetch(fetchRequest)
                let cards = cardEntities.map { entity in
                    Card(
                        id: entity.id,
                        cardName: entity.cardName ?? "",
                        cardLevel: Int(entity.cardLevel),
                        cardType: CardType(rawValue: entity.cardType ?? "")
                            ?? .special,
                        cardDetail: entity.cardDetail ?? ""
                    )
                }
                single(.success(cards))
            } catch {
                single(.failure(error))
            }

            return Disposables.create()
        }
    }

    private func mapDatabaseErrorDeckSettingError(_ error: Error) -> Error {
        if let dbError = error as? DatabaseServiceError {
            switch dbError {
            case .writeFailed(let firebaseError):
                return CardError.writeFailed(firebaseError)
            case .dataDecodingError(let decodingError):
                return CardError.invalidData(decodingError)
            default:
                return CardError.unknownError
            }
        } else {
            return CardError.unknownError
        }
    }
}
