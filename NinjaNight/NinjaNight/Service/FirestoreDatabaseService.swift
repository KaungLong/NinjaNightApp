import FirebaseFirestore
import RxSwift

enum DatabaseServiceError: Error {
    case noDataFound
    case writeFailed(Error)
    case readFailed(Error)

    var localizedDescription: String {
        switch self {
        case .noDataFound:
            return "No data found in Firestore."
        case .writeFailed(let error):
            return "Failed to write data: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read data: \(error.localizedDescription)"
        }
    }
}

protocol DatabaseServiceProtocol {
    func createNewRoom(_ room: Room) -> Single<Void>
    func fetchRoom(with invitationCode: String) -> Single<Room>
    func joinRoom(roomID: String, player: Player) -> Completable
    func fetchPlayerList(forRoomWithID roomID: String) -> Single<[Player]>
}

class FirestoreDatabaseService: DatabaseServiceProtocol {
    private let db = Firestore.firestore()
 
    func createNewRoom(_ room: Room) -> Single<Void> {
        let roomData = room.toDictionary()
        return Single.create { single in
            self.db.collection("RoomList").addDocument(data: roomData) { error in
                if let error = error {
                    single(.failure(DatabaseServiceError.writeFailed(error)))
                } else {
                    single(.success(()))
                }
            }
            return Disposables.create()
        }
    }

    func fetchRoom(with invitationCode: String) -> Single<Room> {
        return Single.create { single in
            self.db.collection("RoomList")
                .whereField("roomInvitationCode", isEqualTo: invitationCode)
                .getDocuments { snapshot, error in
                    if let error = error {
                        single(.failure(DatabaseServiceError.readFailed(error)))
                        return
                    }

                    guard let documents = snapshot?.documents, let document = documents.first else {
                        single(.failure(DatabaseServiceError.noDataFound))
                        return
                    }

                    do {
                        let room = try document.data(as: Room.self)
                        single(.success(room))
                    } catch {
                        single(.failure(DatabaseServiceError.readFailed(error)))
                    }
                }
            return Disposables.create()
        }
    }

    func joinRoom(roomID: String, player: Player) -> Completable {
        return Completable.create { completable in
            do {
                let playerData = try Firestore.Encoder().encode(player)
                self.db.collection("RoomList").document(roomID).collection("RoomPlayerList")
                    .addDocument(data: playerData) { error in
                        if let error = error {
                            completable(.error(DatabaseServiceError.writeFailed(error)))
                        } else {
                            completable(.completed)
                        }
                    }
            } catch {
                completable(.error(DatabaseServiceError.writeFailed(error)))
            }
            return Disposables.create()
        }
    }
    
    func fetchPlayerList(forRoomWithID roomID: String) -> Single<[Player]> {
           return Single.create { single in
               self.db.collection("RoomList").document(roomID).collection("RoomPlayerList")
                   .getDocuments { snapshot, error in
                       if let error = error {
                           single(.failure(DatabaseServiceError.readFailed(error)))
                           return
                       }

                       guard let documents = snapshot?.documents else {
                           single(.success([])) //TODO: 這邊應該要返回某個錯誤型態
                           return
                       }

                       do {
                           let players = try documents.map { try $0.data(as: Player.self) }
                           single(.success(players))
                       } catch {
                           single(.failure(DatabaseServiceError.readFailed(error)))
                       }
                   }
               return Disposables.create()
           }
       }
}

