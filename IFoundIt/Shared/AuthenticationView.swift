//
//  Authentication.swift
//  IFoundIt
//
//  Created by Nathan Wick on 3/4/22.
//

import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth
import AuthenticationServices
import CryptoKit

struct AuthenticationView: View {
    @State var isLoading: Bool = false
    @AppStorage("userID") var userID = "Unknown ID"
    @AppStorage("userImage") var userImage = URL("https://nathanwick.com/img/user.png")
    @AppStorage("userName") var userName = "Unknown Name"
    @AppStorage("userEmail") var userEmail = "Unknown Email"
    @AppStorage("logStatus") var logStatus = false
    let appleButton = ASAuthorizationAppleIDButton(type: .continue, style: .black) // TODO Style
    var body: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: GetRect().height / 3)
                .padding(.horizontal, 20)
                .background(
                    Circle()
                        .fill(Color("LightBlue"))
                        .scaleEffect(2)
                )
            VStack(spacing: 20) {
                Text("Found not Lost")
                    .font(.title)
                    .fontWeight(.bold)
                Button(action: {
                    SignInWithGoogle()
                }, label: {
                    Text("Sign In With Google")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .cornerRadius(25)
                })
                .padding(.top, 80)
                Button(action: {
                    // startSignInWithAppleFlow()
                }, label: {
                    Text("Sign In With Apple")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .cornerRadius(25)
                })
                .padding(.top, 20)
            }
            .padding()
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(
            ZStack {
                if isLoading {
                    Color.black
                        .opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView()
                        .font(.title2)
                        .frame(width: 60, height: 50)
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        )
    }
    
    func SignInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        isLoading = true
        GIDSignIn.sharedInstance.signIn(with: config, presenting: GetRootViewController()) {[self] user, error in
            if let error = error {
                isLoading = false
                print(error.localizedDescription)
                return
            }
            guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken
            else {
                isLoading = false
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            // Firebase Auth
            Auth.auth().signIn(with: credential) { result, error in
                isLoading = false
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                guard let user = result?.user else {
                    return
                }
                userID = user.uid
                userImage = user.photoURL ?? URL("https://nathanwick.com/img/user.png")
                userName = user.displayName ?? "Unknown Name"
                userEmail = user.email ?? "Unknown Email"
                withAnimation {
                    logStatus = true
                }
            }
        }
    }
    
//    // Unhashed nonce.
//    fileprivate var currentNonce: String?

//    @available(iOS 13, *)
//    func startSignInWithAppleFlow() {
//        let nonce = randomNonceString()
//        currentNonce = nonce
//        let appleIDProvider = ASAuthorizationAppleIDProvider()
//        let request = appleIDProvider.createRequest()
//        request.requestedScopes = [.fullName, .email]
//        request.nonce = sha256(nonce)
//
//        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
//        authorizationController.delegate = self
//        authorizationController.presentationContextProvider = self
//        authorizationController.performRequests()
//    }
//
//    @available(iOS 13, *)
//    private func sha256(_ input: String) -> String {
//        let inputData = Data(input.utf8)
//        let hashedData = SHA256.hash(data: inputData)
//        let hashString = hashedData.compactMap {
//            String(format: "%02x", $0)
//        }.joined()
//
//        return hashString
//    }
//
//    private func randomNonceString(length: Int = 32) -> String {
//        precondition(length > 0)
//        let charset: [Character] =
//        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//        var result = ""
//        var remainingLength = length
//
//        while remainingLength > 0 {
//            let randoms: [UInt8] = (0 ..< 16).map { _ in
//                var random: UInt8 = 0
//                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
//                if errorCode != errSecSuccess {
//                    fatalError(
//                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
//                    )
//                }
//                return random
//            }
//
//            randoms.forEach { random in
//                if remainingLength == 0 {
//                    return
//                }
//
//                if random < charset.count {
//                    result.append(charset[Int(random)])
//                    remainingLength -= 1
//                }
//            }
//        }
//
//        return result
//    }
}

extension View {
    func GetRect() -> CGRect {
        return UIScreen.main.bounds
    }
    func GetRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }
        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }
        return root
    }
}

extension URL {
    init(_ string: StaticString) {
        self.init(string: "\(string)")!
    }
}

//@available(iOS 13.0, *)
//extension AuthenticationView: ASAuthorizationControllerDelegate {
//
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//            guard let nonce = currentNonce else {
//                fatalError("Invalid state: A login callback was received, but no login request was sent.")
//            }
//            guard let appleIDToken = appleIDCredential.identityToken else {
//                print("Unable to fetch identity token")
//                return
//            }
//            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
//                return
//            }
//            // Initialize a Firebase credential.
//            let credential = OAuthProvider.credential(withProviderID: "apple.com", IDToken: idTokenString, rawNonce: nonce)
//            // Sign in with Firebase.
//            Auth.auth().signIn(with: credential) { (authResult, error) in
//                if error {
//                    // Error. If error.code == .MissingOrInvalidNonce, make sure
//                    // you're sending the SHA256-hashed nonce as a hex string with
//                    // your request to Apple.
//                    print(error.localizedDescription)
//                    return
//                }
//                // User is signed in to Firebase with Apple.
//                // ...
//            }
//        }
//    }

//    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//        // Handle error.
//        print("Sign in with Apple errored: \(error)")
//    }
// }
