import Foundation
import Combine
import FirebaseAuth
import GoogleSignIn

final class AuthManager: ObservableObject {
    @Published var isSignedIn = false
    @Published var userName: String? = nil
    @Published var errorMessage: String? = nil

    private var handler: AuthStateDidChangeListenerHandle?

    init() {
        // Listen to live authorization state changes from Firebase
        handler = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            if let user = user {
                self?.userName = user.email
                self?.isSignedIn = true
            } else {
                self?.userName = nil
                self?.isSignedIn = false
            }
        }
     }

    deinit {
        if let handler = handler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }

    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                print("Firebase Auth Sign In Error: \(error.localizedDescription) - Details: \(error)")
                self?.errorMessage = error.localizedDescription
            } else {
                self?.errorMessage = nil
            }
        }
    }

    func signUp(email: String, password: String, confirmPassword: String) {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                print("Firebase Auth Sign Up Error: \(error.localizedDescription) - Details: \(error)")
                self?.errorMessage = error.localizedDescription
            } else {
                self?.errorMessage = nil
            }
        }
    }

    func signInWithSocial(provider: String) {
        if provider == "Google" {
            signInWithGoogle()
        } else {
            // Mock social authentication for now until other provider SDK client tokens are linked
            userName = "\(provider.lowercased())_user@example.com"
            isSignedIn = true
            errorMessage = nil
        }
    }

    @MainActor
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Unable to find the root view controller for Google Sign-In."
            return
        }

        // Traverse to find the topmost presented view controller
        var topmostViewController = rootViewController
        while let presented = topmostViewController.presentedViewController {
            topmostViewController = presented
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: topmostViewController) { [weak self] signInResult, error in
            if let error = error {
                let nsError = error as NSError
                // Code -5 means the user cancelled the dialog, so we swallow it to avoid scary error text
                if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                    return
                }
                print("Google Sign-In Error: \(error.localizedDescription)")
                self?.errorMessage = error.localizedDescription
                return
            }

            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                self?.errorMessage = "Google ID token was missing."
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Google Auth Error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.errorMessage = nil
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
