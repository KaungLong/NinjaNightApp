import Foundation
import FirebaseFirestore

struct Room: Decodable {
    @DocumentID var id: String?
    var roomInvitationCode: String
    var roomCapacity: Int
    var isRoomPublic: Bool
    var roomPassword: String
    var rommHostID: String
    var currentPlayerCount: Int?
    var isFull: Bool?
    
    init(
        id: String? = nil,
        roomInvitationCode: String,
        roomCapacity: Int,
        isRoomPublic: Bool,
        roomPassword: String,
        rommHostID: String,
        currentPlayerCount: Int? = nil,
        isFull: Bool? = nil
    ) {
        self.id = id
        self.roomInvitationCode = roomInvitationCode
        self.roomCapacity = roomCapacity
        self.isRoomPublic = isRoomPublic
        self.roomPassword = roomPassword
        self.rommHostID = rommHostID
    }

    init(dictionary: [String: Any], id: String? = nil) throws {
        guard
            let roomInvitationCode = dictionary["roomInvitationCode"] as? String,
            let roomCapacity = dictionary["roomCapacity"] as? Int,
            let isRoomPublic = dictionary["isRoomPublic"] as? Bool,
            let roomPassword = dictionary["roomPassword"] as? String,
            let rommHostID = dictionary["rommHostID"] as? String
        else {
            throw DatabaseServiceError.documentNotFound
        }

        self.id = id
        self.roomInvitationCode = roomInvitationCode
        self.roomCapacity = roomCapacity
        self.isRoomPublic = isRoomPublic
        self.roomPassword = roomPassword
        self.rommHostID = rommHostID
        self.currentPlayerCount = nil
        self.isFull = nil
    }

    func toDictionary() -> [String: Any] {
        return [
            "roomInvitationCode": roomInvitationCode,
            "roomCapacity": roomCapacity,
            "isRoomPublic": isRoomPublic,
            "roomPassword": roomPassword,
            "rommHostID": rommHostID
        ]
    }
}

extension Room {
    static func generateRandomInvitationCode() -> String {
        return "\(Int.random(in: 10000000...99999999))"
    }
}
