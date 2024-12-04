import FirebaseFirestore

struct Card: Codable, Identifiable {
    @DocumentID var id: String?
    let cardName: String
    let cardLevel: Int
    let cardType: CardType
    let cardDetail: String

    init(
        id: String? = nil,
        cardName: String,
        cardLevel: Int,
        cardType: CardType,
        cardDetail: String
    ) {
        self.id = id
        self.cardName = cardName
        self.cardLevel = cardLevel
        self.cardType = cardType
        self.cardDetail = cardDetail
    }

    init(dictionary: [String: Any]) throws {
        guard
            let cardName = dictionary["cardName"] as? String,
            let cardLevel = dictionary["cardLevel"] as? Int,
            let cardTypeRaw = dictionary["cardType"] as? String,
            let cardType = CardType(rawValue: cardTypeRaw),
            let cardDetail = dictionary["cardDetail"] as? String
        else {
            throw DatabaseServiceError.documentNotFound
        }

        self.cardName = cardName
        self.cardLevel = cardLevel
        self.cardType = cardType
        self.cardDetail = cardDetail
    }

    func toDictionary() -> [String: Any] {
        return [
            "cardName": cardName,
            "cardLevel": cardLevel,
            "cardType": cardType.rawValue,
            "cardDetail": cardDetail,
        ]
    }
}

enum CardType: String, Codable {
    case spy = "密探"
    case hermit = "隱士"
    case liar = "騙徒"
    case blindAssassin = "盲眼刺客"
    case jonin = "上忍"
    case counterattack = "反制"
    case special = "特殊"

    init?(rawValue: String) {
        switch rawValue {
        case "密探": self = .spy
        case "隱士": self = .hermit
        case "騙徒": self = .liar
        case "盲眼刺客": self = .blindAssassin
        case "上忍": self = .jonin
        case "反制": self = .counterattack
        case "特殊": self = .special
        default: return nil
        }
    }
}
