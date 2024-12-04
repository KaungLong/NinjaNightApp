import FirebaseFirestore

struct RoundState: Codable, Identifiable {
    @DocumentID var id: String?
    let faction: String
    var isFactionRevealed: Bool
    var currentHand: [String]
    var isAlive: Bool

    init(
        id: String? = nil,
        faction: String,
        isFactionRevealed: Bool,
        currentHand: [String],
        isAlive: Bool
    ) {
        self.id = id
        self.faction = faction
        self.isFactionRevealed = isFactionRevealed
        self.currentHand = currentHand
        self.isAlive = isAlive
    }

    init(dictionary: [String: Any]) throws {
        guard
            let faction = dictionary["faction"] as? String,
            let isFactionRevealed = dictionary["isFactionRevealed"] as? Bool,
            let currentHand = dictionary["currentHand"] as? [String],
            let isAlive = dictionary["isAlive"] as? Bool
        else {
            throw DatabaseServiceError.documentNotFound
        }

        self.faction = faction
        self.isFactionRevealed = isFactionRevealed
        self.currentHand = currentHand
        self.isAlive = isAlive
    }

    func toDictionary() -> [String: Any] {
        return [
            "faction": faction,
            "isFactionRevealed": isFactionRevealed,
            "currentHand": currentHand,
            "isAlive": isAlive,
        ]
    }
}
