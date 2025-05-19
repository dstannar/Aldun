//
//  Integration.swift
//  Alldun
//
//  Created by Jakob Marrone on 5/15/25.
//
import Foundation
import UIKit

func uploadTaskImage(image: UIImage, userId: Int) {
    guard let url = URL(string: "https://127.0.0.1:8000/tasks/") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var data = Data()

    // Add form fields
    let params: [String: String] = [
        "start_time": "2024-06-01T10:00:00",
        "end_time": "2024-06-01T11:00:00",
        "category": "Work",
        "priority": "high",
        "visibility": "true",
        "user_id": "\(userId)"
    ]
    for (key, value) in params {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(value)\r\n".data(using: .utf8)!)
    }

    // Add image file
    if let imageData = image.jpegData(compressionQuality: 0.8) {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"image1\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n".data(using: .utf8)!)
    }

    data.append("--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = data

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            print(String(data: data, encoding: .utf8) ?? "No response")
        } else if let error = error {
            print("Error: \(error)")
        }
    }.resume()
}
