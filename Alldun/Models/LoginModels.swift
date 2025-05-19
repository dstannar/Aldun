//
//  LoginModels.swift
//  Alldun
//
//  Created by Jakob Marrone on 5/19/25.
//

import Foundation

struct UserCreate: Codable {
    let username: String
    let email: String
    let password: String
}

func signUp(username: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
    guard let url = URL(string: "http://127.0.0.1:8000/users/") else { // Or /users/signup/ or /auth/register etc.
        completion(false, "Invalid URL for SignUp")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let user = UserCreate(username: username, email: email, password: password)
    do {
        request.httpBody = try JSONEncoder().encode(user)
    } catch {
        completion(false, "Encoding error")
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(false, error.localizedDescription)
        } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            completion(true, nil)
        } else {
            let errorMsg = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
            completion(false, errorMsg)
        }
    }.resume()
}

func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
    // This is a MOCK login. In a real app, you'd POST to /login or similar.
    // For now, just check if a user exists with this email and password.
    // The previous implementation incorrectly tried to GET a list of users from /users/login/
    // For a real login, you'd typically POST credentials.
    // For this mock, we'll just simulate a success/failure.
    guard let url = URL(string: "http://127.0.0.1:8000/auth/token/") else { // Example token endpoint
        completion(false, "Invalid URL for Login")
        return
    }

    // MOCK IMPLEMENTATION:
    // In a real scenario, you would make a POST request with email and password
    // For now, let's assume specific credentials for mock success
    if email == "test@example.com" && password == "password123" {
        print("Mock login successful for \(email)")
        completion(true, nil)
    } else {
        print("Mock login failed for \(email)")
        completion(false, "Invalid mock credentials")
    }
}
