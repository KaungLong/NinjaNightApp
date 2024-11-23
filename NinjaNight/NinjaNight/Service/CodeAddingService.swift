import Foundation
import RxSwift

protocol CodeAddingProtocol {
    func checkRoomExists(invitationCode: String) -> Single<Bool>
}

class CodeAddingService: CodeAddingProtocol {
    private let adapter: FirestoreAdapterProtocol

    init(adapter: FirestoreAdapterProtocol) {
        self.adapter = adapter
    }

    func checkRoomExists(invitationCode: String) -> Single<Bool> {
        return adapter.queryDocuments(
            collection: "RoomList",
            field: "roomInvitationCode",
            value: invitationCode
        ).map { (rooms: [Room]) in
            !rooms.isEmpty
        }
    }
}
