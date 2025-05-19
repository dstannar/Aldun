//
// Networking.swift
//  Alldun
//
//  Created by Jakob Marrone on 5/15/25.
import Foundation

func createUser() {
    guard let url = URL(string: "https://127.0.0.1:8000/users/") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let user = UserCreate(username: "testuser", email: "test@example.com", password: "password123")
    request.httpBody = try? JSONEncoder().encode(user)

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            print(String(data: data, encoding: .utf8) ?? "No response")
        } else if let error = error {
            print("Error: \(error)")
        }
    }.resume()
}
