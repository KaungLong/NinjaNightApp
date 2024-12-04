import FirebaseFirestore

struct Player: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    var isReady: Bool
    var isOnline: Bool
    var lastHeartbeat: Timestamp
    var score: Int

    init(
        id: String? = nil,
        name: String,
        isReady: Bool,
        isOnline: Bool,
        lastHeartbeat: Timestamp,
        score: Int = 0
    ) {
        self.id = id
        self.name = name
        self.isReady = isReady
        self.isOnline = isOnline
        self.lastHeartbeat = lastHeartbeat
        self.score = score
    }

    init(dictionary: [String: Any]) throws {
        guard
            let name = dictionary["name"] as? String,
            let isReady = dictionary["isReady"] as? Bool,
            let isOnline = dictionary["isOnline"] as? Bool,
            let lastHeartbeat = dictionary["lastHeartbeat"] as? Timestamp,
            let score = dictionary["score"] as? Int
        else {
            throw DatabaseServiceError.documentNotFound
        }

        self.name = name
        self.isReady = isReady
        self.isOnline = isOnline
        self.lastHeartbeat = lastHeartbeat
        self.score = score
    }

    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "isReady": isReady,
            "isOnline": isOnline,
            "lastHeartbeat": lastHeartbeat,
            "score": score,
        ]
    }
}
