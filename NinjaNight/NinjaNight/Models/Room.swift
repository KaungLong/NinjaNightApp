import Foundation
import FirebaseFirestore

struct Room: Decodable {
    @DocumentID var id: String?
    var roomInvitationCode: String
    var roomCapacity: Int
    var isRoomPublic: Bool
    var roomPassword: String
    var rommHostID: String

    func toDictionary() -> [String: Any] {
        return [
            "roomInvitationCode" : roomInvitationCode,
            "roomCapacity" : roomCapacity,
            "isRoomPublic" : isRoomPublic,
            "roomPassword" : roomPassword,
            "rommHostID" : rommHostID
        ]
    }
}

extension Room {
    static func generateRandomInvitationCode() -> String {
        return "\(Int.random(in: 10000000...99999999))"
    }
}
