import Firebase
import Foundation
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
            self.db.collection(collection).document(documentID).getDocument {
                snapshot, error in
                if let error = error {
                    single(.failure(DatabaseServiceError.readFailed(error)))
                } else if let snapshot = snapshot, snapshot.exists {
                    do {
                        let object = try snapshot.data(as: T.self)
                        single(.success(object))
                    } catch {
                        single(.failure(DatabaseServiceError.readFailed(error)))
                    }
                } else {
                    single(.failure(DatabaseServiceError.noDataFound))
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
        return Single.create { single in
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
                                .failure(DatabaseServiceError.readFailed(error))
                            )
                        }
                    } else {
                        single(.failure(DatabaseServiceError.noDataFound))
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
        return Single.create { single in
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
                    single(.failure(DatabaseServiceError.noDataFound))
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
                        observer.onError(DatabaseServiceError.noDataFound)
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
                        observer.onError(DatabaseServiceError.readFailed(error))
                    } else if let documents = snapshot?.documents {
                        do {
                            let objects: [T] = try documents.map { document in
                                return try document.data(as: T.self)
                            }
                            observer.onNext(objects)
                        } catch {
                            observer.onError(
                                DatabaseServiceError.readFailed(error))
                        }
                    } else {
                        observer.onError(DatabaseServiceError.noDataFound)
                    }
                }
            return Disposables.create {
                listener.remove()
            }
        }
    }
}
