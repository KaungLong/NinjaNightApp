import FirebaseFirestore

struct Player: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    var isReady: Bool
    var isOnline: Bool
    var lastHeartbeat: Timestamp
}
