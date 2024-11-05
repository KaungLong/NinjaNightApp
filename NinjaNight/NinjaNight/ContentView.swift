//
//  ContentView.swift
//  NinjaNight
//
//  Created by 陳彥琮 on 2024/11/4.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct ContentView: View {
    @State private var connectionMessage = "Testing Firestore connection..."

    var body: some View {
        BaseView(title: "登入頁面") {
            LoginView(connectionMessage: $connectionMessage)
        }
        .padding()
        .onAppear(perform: testFirestoreConnection)
    }

    func testFirestoreConnection() {
        let db = Firestore.firestore()
        let testCollection = db.collection("testCollection")

        let testData: [String: Any] = ["message": "Hello Firestore!"]
        testCollection.addDocument(data: testData) { error in
            if let error = error {
                connectionMessage =
                    "Error writing to Firestore: \(error.localizedDescription)"
                return
            } else {
                connectionMessage = "Successfully wrote test data to Firestore."

                testCollection.getDocuments { (snapshot, error) in
                    if let error = error {
                        connectionMessage =
                            "Error connecting to Firestore: \(error.localizedDescription)"
                    } else {
                        connectionMessage =
                            "Successfully connected to Firestore and retrieved data!"
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
