import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import SwiftUI
import FirebaseFirestore

struct LoginView: View {
    @State private var isSignedIn = false
    @State private var userName = ""
    @State private var userEmail = ""
    @Binding  var connectionMessage: String

    var body: some View {
        VStack {
            Text(connectionMessage)
            if isSignedIn {
                Text("Welcome, \(userName)!")
                Text("Email: \(userEmail)")
                Button("Sign Out", action: signOut)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else {
                Button("Sign in with Google", action: signInWithGoogle)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }

    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
            if let error = error {
                print("Error signing in with Google: \(error.localizedDescription)")
                return
            }
            
            // 確保成功獲取 Google 用戶和其憑證
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                print("Error: Unable to retrieve Google ID token")
                return
            }
            
            let accessToken = user.accessToken.tokenString

            // 使用 Google ID token 和 access token 來獲取 Firebase 憑證
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // 使用 Firebase 憑證登錄到 Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign in error: \(error.localizedDescription)")
                    connectionMessage = "Firebase sign in error: \(error.localizedDescription)"
                    return
                }
                print("Successfully signed in with Firebase!")
                self.isSignedIn = true
                self.userName = authResult?.user.displayName ?? "No Name"
                self.userEmail = authResult?.user.email ?? "No Email"
                
                // 成功登入 Firebase 後執行 Firestore 測試
                testFirestoreConnection()
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
    }

    func getRootViewController() -> UIViewController {
        guard
            let screen = UIApplication.shared.connectedScenes.first
                as? UIWindowScene
        else {
            fatalError("Unable to get UIWindowScene")
        }
        guard let root = screen.windows.first?.rootViewController else {
            fatalError("Unable to get rootViewController")
        }
        return root
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

struct BaseView<Content: View>: View {
    var title: String
    var backgroundColor: Color
    var content: Content

    init(
        title: String, backgroundColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        VStack {
            Text(title)
                .font(.largeTitle)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)

            Divider()

            content
                .padding()
                .background(backgroundColor)
                .cornerRadius(10)
                .shadow(radius: 5)

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .edgesIgnoringSafeArea(.all)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginViewWrapper()
    }

    struct LoginViewWrapper: View {
        @State private var connectionMessage = "Testing Firestore connection..."
        
        var body: some View {
            LoginView(connectionMessage: $connectionMessage)
        }
    }
}
