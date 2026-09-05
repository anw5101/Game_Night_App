import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUpMode = false

    var isFormValid: Bool {
        if isSignUpMode {
            return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    Text(isSignUpMode ? "Create an account to save favorites and discover game nights." : "Sign in to save favorites and manage your profile.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 10)

                    // Email field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email Address")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        TextField("name@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        SecureField("••••••••", text: $password)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Confirm Password (Sign-Up mode only)
                    if isSignUpMode {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Confirm Password")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            SecureField("••••••••", text: $confirmPassword)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }

                    // Primary Button
                    Button(action: handlePrimaryAction) {
                        Text(isSignUpMode ? "Create Account" : "Sign In")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)

                    // Form Mode Toggle
                    Button(action: { withAnimation { isSignUpMode.toggle(); authManager.errorMessage = nil } }) {
                        Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }

                    // Divider
                    HStack {
                        VStack { Divider() }
                        Text("or continue with")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        VStack { Divider() }
                    }
                    .padding(.vertical, 8)

                    // Social buttons
                    VStack(spacing: 12) {
                        // Google Sign-In
                        Button(action: { handleSocialAction(provider: "Google") }) {
                            HStack(spacing: 10) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                Text("Continue with Google")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(isSignUpMode ? "Create Account" : "Game Night Login")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func handlePrimaryAction() {
        if isSignUpMode {
            authManager.signUp(email: email, password: password, confirmPassword: confirmPassword)
        } else {
            authManager.signIn(email: email, password: password)
        }
        if authManager.isSignedIn {
            dismiss()
        }
    }

    private func handleSocialAction(provider: String) {
        authManager.signInWithSocial(provider: provider)
        if authManager.isSignedIn {
            dismiss()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authManager: AuthManager())
    }
}
