import Foundation
import Combine

struct User: Identifiable, Hashable {
    let id: UUID
    var username: String
    var fullName: String
    var bio: String?
    var profileImageName: String?

    init(id: UUID = UUID(), username: String, fullName: String, bio: String? = nil, profileImageName: String? = nil) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.bio = bio
        self.profileImageName = profileImageName
    }
}

class UserStore: ObservableObject {
    @Published var allUsers: [User] = []
    var currentUser: User? {
        allUsers.first
    }

    init() {
        self.allUsers = [
            User(username: "jakob_m", fullName: "Jakob Marrone", bio: "Striving for progress, not perfection.", profileImageName: "profile_jakob"),
            User(username: "sarah_k", fullName: "Sarah Kim", bio: "Coding and coffee.", profileImageName: "default_avatar"),
            User(username: "mike_b", fullName: "Mike Brown", bio: "Tech enthusiast.", profileImageName: "default_avatar"),
            User(username: "jess_w", fullName: "Jessica Wong", bio: "Creating beautiful apps.", profileImageName: "default_avatar"),
            User(username: "alex_p_dev", fullName: "Alex (AI Developer)", bio: "Helping build awesome things!", profileImageName: "default_avatar"),
            User(username: "chris_adams", fullName: "Chris Adams", bio: "Exploring new ideas.", profileImageName: "default_avatar")
        ]
    }

    func updateUserBio(userID: UUID, newBio: String) {
        if let index = allUsers.firstIndex(where: { $0.id == userID }) {
            allUsers[index].bio = newBio.isEmpty ? nil : newBio
            print("UserStore: Updated bio for user \(userID). New bio: \(allUsers[index].bio ?? "nil")")
        } else {
            print("UserStore: Failed to update bio. User \(userID) not found.")
        }
    }
}
