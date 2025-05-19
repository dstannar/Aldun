import SwiftUI

struct UniqueBackendCheckView: View {
    @State private var backendMessage: String = "No response yet"

    var body: some View {
        VStack {
            Text(backendMessage)
                .padding()
            Button("Test Backend Connection") {
                testBackendConnection()
            }
        }
    }

    func testBackendConnection() {
        guard let url = URL(string: "http://127.0.0.1:8000/") else {
            DispatchQueue.main.async {
                backendMessage = "Error: Invalid URL"
            }
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    backendMessage = "Error: \(error.localizedDescription)"
                }
            } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    backendMessage = "Backend: \(responseString)"
                }
            } else {
                DispatchQueue.main.async {
                    backendMessage = "Error: No data or failed to decode response."
                }
            }
        }.resume()
    }
}
