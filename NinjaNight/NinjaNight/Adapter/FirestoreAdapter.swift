import Firebase
import Foundation
import RxSwift

enum DatabaseServiceError: Error {
    case unknownError
    case firebaseError(Error)
    case documentNotFound
    case dataDecodingError(Error)
    case writeFailed(Error)
    case readFailed(Error)
    case deleteFailed(Error)
    case updateFailed(Error)
    case listenerFailed(Error)
}

protocol FirestoreAdapterProtocol {
    func addDocument(
        collection: String,
        data: [String: Any]
    ) -> Completable

    func addDocument(
        collection: String,
        documentID: String,
        data: [String: Any]
    ) -> Completable

    func fetchDocument<T: Decodable>(
        collection: String,
        documentID: String
    ) -> Single<T>

    func queryDocuments<T: Decodable>(
        collection: String,
        field: String,
        value: Any
    ) -> Single<[T]>

    func updateDocument(
        collection: String,
        documentID: String,
        data: [String: Any]
    ) -> Completable

    func deleteDocument(
        collection: String,
        documentID: String
    ) -> Completable

    func queryCollection<T: Decodable>(
        collection: String
    ) -> Single<[T]>

    func listenToDocument<T: Decodable>(
        collection: String,
        documentID: String
    ) -> Observable<T>

    func listenToCollection<T: Decodable>(
        collection: String
    ) -> Observable<[T]>
}

class FirestoreAdapter: FirestoreAdapterProtocol {
    private let db = Firestore.firestore()

    func addDocument(
         collection: String,
         data: [String: Any]
     ) -> Completable {
         return Completable.create { completable in
             self.db.collection(collection).addDocument(data: data) { error in
                 if let error = error {
                     completable(.error(DatabaseServiceError.writeFailed(error)))
                 } else {
                     completable(.completed)
                 }
             }
             return Disposables.create()
         }
     }

     func addDocument(
         collection: String,
         documentID: String,
         data: [String: Any]
     ) -> Completable {
         return Completable.create { completable in
             self.db.collection(collection).document(documentID).setData(data) { error in
                 if let error = error {
                     completable(.error(DatabaseServiceError.writeFailed(error)))
                 } else {
                     completable(.completed)
                 }
             }
             return Disposables.create()
         }
     }

    func fetchDocument<T: Decodable>(
        collection: String,
        documentID: String
    ) -> Single<T> {
        return Single.create { single in
            self.db.collection(collection).document(documentID).getDocument { snapshot, error in
                if let error = error {
                    single(.failure(DatabaseServiceError.readFailed(error)))
                } else if let snapshot = snapshot, snapshot.exists {
                    do {
                        let object = try snapshot.data(as: T.self)
                        single(.success(object))
                    } catch {
                        single(.failure(DatabaseServiceError.dataDecodingError(error)))
                    }
                } else {
                    single(.failure(DatabaseServiceError.documentNotFound))
                }
            }
            return Disposables.create()
        }
    }

    func queryDocuments<T: Decodable>(
        collection: String,
        field: String,
        value: Any
    ) -> Single<[T]> {
        return Single.create { (single: @escaping (SingleEvent<[T]>) -> Void) in
            self.db.collection(collection).whereField(field, isEqualTo: value)
                .getDocuments { snapshot, error in
                    if let error = error {
                        single(.failure(DatabaseServiceError.readFailed(error)))
                    } else if let documents = snapshot?.documents {
                        do {
                            let objects: [T] = try documents.map { document in
                                return try document.data(as: T.self)
                            }
                            single(.success(objects))
                        } catch {
                            single(
                                .failure(DatabaseServiceError.dataDecodingError(error))
                            )
                        }
                    } else {
                        single(.failure(DatabaseServiceError.documentNotFound))
                    }
                }
            return Disposables.create()
        }
    }

    func updateDocument(
        collection: String,
        documentID: String,
        data: [String: Any]
    ) -> Completable {
        return Completable.create { completable in
            self.db.collection(collection).document(documentID).updateData(data)
            { error in
                if let error = error {
                    completable(.error(DatabaseServiceError.writeFailed(error)))
                } else {
                    completable(.completed)
                }
            }
            return Disposables.create()
        }
    }

    func deleteDocument(collection: String, documentID: String) -> Completable {
        return Completable.create { completable in
            self.db.collection(collection).document(documentID).delete {
                error in
                if let error = error {
                    completable(.error(DatabaseServiceError.writeFailed(error)))
                } else {
                    completable(.completed)
                }
            }
            return Disposables.create()
        }
    }

    func queryCollection<T: Decodable>(
        collection: String
    ) -> Single<[T]> {
        return Single.create { (single: @escaping (SingleEvent<[T]>) -> Void) in
            self.db.collection(collection).getDocuments { snapshot, error in
                if let error = error {
                    single(.failure(DatabaseServiceError.readFailed(error)))
                } else if let documents = snapshot?.documents {
                    do {
                        let objects: [T] = try documents.map { document in
                            return try document.data(as: T.self)
                        }
                        single(.success(objects))
                    } catch {
                        single(.failure(DatabaseServiceError.readFailed(error)))
                    }
                } else {
                    single(.failure(DatabaseServiceError.documentNotFound))
                }
            }
            return Disposables.create()
        }
    }

    func listenToDocument<T: Decodable>(
        collection: String,
        documentID: String
    ) -> Observable<T> {
        return Observable.create { observer in
            let listener = self.db.collection(collection).document(documentID)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        observer.onError(DatabaseServiceError.readFailed(error))
                    } else if let snapshot = snapshot, snapshot.exists {
                        do {
                            let object = try snapshot.data(as: T.self)
                            observer.onNext(object)
                        } catch {
                            observer.onError(
                                DatabaseServiceError.readFailed(error))
                        }
                    } else {
                        observer.onError(DatabaseServiceError.documentNotFound)
                    }
                }
            return Disposables.create {
                listener.remove()
            }
        }
    }

    func listenToCollection<T: Decodable>(
        collection: String
    ) -> Observable<[T]> {
        return Observable.create { observer in
            let listener = self.db.collection(collection)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        observer.onError(DatabaseServiceError.listenerFailed(error))
                    } else if let documents = snapshot?.documents {
                        do {
                            let objects: [T] = try documents.map { document in
                                return try document.data(as: T.self)
                            }
                            observer.onNext(objects)
                        } catch {
                            observer.onError(DatabaseServiceError.dataDecodingError(error))
                        }
                    } else {
                        observer.onError(DatabaseServiceError.documentNotFound)
                    }
                }
            return Disposables.create {
                listener.remove()
            }
        }
    }
}

extension DatabaseServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unknownError:
            return NSLocalizedString("An unknown error occurred.", comment: "")
        case .firebaseError(let error):
            return NSLocalizedString("Firebase error: \(error.localizedDescription)", comment: "")
        case .documentNotFound:
            return NSLocalizedString("The requested document was not found.", comment: "")
        case .dataDecodingError(let error):
            return NSLocalizedString("Failed to decode data: \(error.localizedDescription)", comment: "")
        case .writeFailed(let error):
            return NSLocalizedString("Failed to write data: \(error.localizedDescription)", comment: "")
        case .readFailed(let error):
            return NSLocalizedString("Failed to read data: \(error.localizedDescription)", comment: "")
        case .deleteFailed(let error):
            return NSLocalizedString("Failed to delete data: \(error.localizedDescription)", comment: "")
        case .updateFailed(let error):
            return NSLocalizedString("Failed to update data: \(error.localizedDescription)", comment: "")
        case .listenerFailed(let error):
            return NSLocalizedString("Failed to listen for data changes: \(error.localizedDescription)", comment: "")
        }
    }
}
