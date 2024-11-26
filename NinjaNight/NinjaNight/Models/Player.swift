import FirebaseFirestore

struct Player: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    var isReady: Bool
    var isOnline: Bool
    var lastHeartbeat: Timestamp
    
    init(
        id: String? = nil,
        name: String,
        isReady: Bool,
        isOnline: Bool,
        lastHeartbeat: Timestamp
    ) {
        self.id = id
        self.name = name
        self.isReady = isReady
        self.isOnline = isOnline
        self.lastHeartbeat = lastHeartbeat
    }

    init(dictionary: [String: Any]) throws {
        guard
            let name = dictionary["name"] as? String,
            let isReady = dictionary["isReady"] as? Bool,
            let isOnline = dictionary["isOnline"] as? Bool,
            let lastHeartbeat = dictionary["lastHeartbeat"] as? Timestamp
        else {
            throw DatabaseServiceError.documentNotFound
        }

        self.name = name
        self.isReady = isReady
        self.isOnline = isOnline
        self.lastHeartbeat = lastHeartbeat
    }

    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "isReady": isReady,
            "isOnline": isOnline,
            "lastHeartbeat": lastHeartbeat
        ]
    }
}
