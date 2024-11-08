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
    func writeData(_ data: [String: Any], to collection: String) -> Single<Void>
    func readData(from collection: String) -> Single<[String: Any]>
}

class FirestoreDatabaseService: DatabaseServiceProtocol {
    private let db = Firestore.firestore()

    func writeData(_ data: [String: Any], to collection: String) -> Single<Void> {
        return Single.create { single in
            self.db.collection(collection).addDocument(data: data) { error in
                if let error = error {
                    single(.failure(DatabaseServiceError.writeFailed(error)))
                } else {
                    single(.success(()))
                }
            }
            return Disposables.create()
        }
    }

    func readData(from collection: String) -> Single<[String: Any]> {
        return Single.create { single in
            self.db.collection(collection).getDocuments { snapshot, error in
                if let error = error {
                    single(.failure(DatabaseServiceError.readFailed(error)))
                } else if let documents = snapshot?.documents {
                    var resultData = [String: Any]()
                    for document in documents {
                        resultData[document.documentID] = document.data()
                    }
                    single(.success(resultData))
                } else {
                    single(.failure(DatabaseServiceError.noDataFound))
                }
            }
            return Disposables.create()
        }
    }
}
