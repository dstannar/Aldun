import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    // You might want to inject an EnvironmentObject for UserStore
    // or pass a closure to handle successful login/signup
    // @EnvironmentObject var userStore: UserStore

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Alldun")
                .font(.largeTitle)
                .padding(.bottom, 20)

            Picker("Mode", selection: $isSignUp) {
                Text("Login").tag(false)
                Text("Sign Up").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 20)

            if isSignUp { 
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: handleLoginOrSignUp) {
                Text(isSignUp ? "Sign Up" : "Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }

    private func handleLoginOrSignUp() {
        guard !email.isEmpty, !password.isEmpty else {
            print("LoginView: Email and password cannot be empty.")
            return
        }
        if isSignUp && username.isEmpty {
            print("LoginView: Username cannot be empty for sign up.")
            return
        }

        if isSignUp {
            print("LoginView: Attempting Sign Up with Username: \(username), Email: \(email)")
            signUp(username: username, email: email, password: password) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("Sign Up Success!")
                    } else {
                        print("Sign Up Error: \(error ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("LoginView: Attempting Login with Email: \(email)")
            login(email: email, password: password) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("Login Success!")
                    } else {
                        print("Login Error: \(error ?? "Unknown error")")
                    }
                }
            }
        }
    }

    func signUp(username: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // TODO: Implement backend connection here for sign up
    }

    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // TODO: Implement backend connection here for login
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
