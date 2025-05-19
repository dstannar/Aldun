import Foundation
import Combine

struct User: Identifiable, Hashable {
    let id: UUID
    var username: String
    var fullName: String
    var bio: String?
    var profileImageName: String?
    var friendIDs: [UUID] = []

    init(id: UUID = UUID(), username: String, fullName: String, bio: String? = nil, profileImageName: String? = nil, friendIDs: [UUID] = []) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.bio = bio
        self.profileImageName = profileImageName
        self.friendIDs = friendIDs
    }
}

class UserStore: ObservableObject {
    @Published var allUsers: [User] = []
    @Published var currentUser: User?

    init() {
        let users = [
            User(username: "jakob", fullName: "Jakob Marrone", bio: "Striving for progress, not perfection.", profileImageName: "profile_jakob"),
            User(username: "sarah_k", fullName: "Sarah Kim", bio: "Coding and coffee.", profileImageName: "default_avatar"),
            User(username: "mike_b", fullName: "Mike Brown", bio: "Tech enthusiast.", profileImageName: "default_avatar"),
            User(username: "jess_w", fullName: "Jessica Wong", bio: "Creating beautiful apps.", profileImageName: "default_avatar"),
            User(username: "chris_adams", fullName: "Chris Adams", bio: "Exploring new ideas.", profileImageName: "default_avatar")
        ]
        self.allUsers = users
        self.currentUser = users.first
    }

    func logout() {
        self.currentUser = nil
        print("UserStore: User logged out. currentUser is now nil.")
    }

    func updateUserBio(userID: UUID, newBio: String) {
        if let index = allUsers.firstIndex(where: { $0.id == userID }) {
            allUsers[index].bio = newBio.isEmpty ? nil : newBio
            if allUsers[index].id == currentUser?.id {
                currentUser?.bio = newBio.isEmpty ? nil : newBio
            }
            print("UserStore: Updated bio for user \(userID). New bio: \(allUsers[index].bio ?? "nil")")
        } else {
            print("UserStore: Failed to update bio. User \(userID) not found.")
        }
    }

    func addFriend(currentUserInitiatorID: UUID, friendToAddID: UUID) {
        guard currentUserInitiatorID != friendToAddID else {
            print("UserStore: Cannot add self as friend.")
            return
        }

        var initiatorUser: User?
        var friendUser: User?
        var initiatorIndex: Int?
        var friendIndex: Int?

        if let idx = allUsers.firstIndex(where: { $0.id == currentUserInitiatorID }) {
            initiatorUser = allUsers[idx]
            initiatorIndex = idx
        }
        if let idx = allUsers.firstIndex(where: { $0.id == friendToAddID }) {
            friendUser = allUsers[idx]
            friendIndex = idx
        }

        guard let initiatorIdx = initiatorIndex, let initiator = initiatorUser,
              let friendIdx = friendIndex, let friend = friendUser else {
            print("UserStore: Error - Could not find one or both users to establish friendship.")
            return
        }
            
        if !initiator.friendIDs.contains(friendToAddID) {
            allUsers[initiatorIdx].friendIDs.append(friendToAddID)
            if currentUser?.id == currentUserInitiatorID {
                currentUser?.friendIDs.append(friendToAddID)
            }
            print("UserStore: \(initiator.username) added \(friend.username) as friend.")
        } else {
            print("UserStore: \(initiator.username) is already friends with \(friend.username).")
        }

        if !friend.friendIDs.contains(currentUserInitiatorID) {
            allUsers[friendIdx].friendIDs.append(currentUserInitiatorID)
            if currentUser?.id == friendToAddID {
                currentUser?.friendIDs.append(currentUserInitiatorID)
            }
            print("UserStore: \(friend.username) added \(initiator.username) as friend (mutual).")
        }
    }
    
    func areFriends(user1ID: UUID, user2ID: UUID) -> Bool {
        guard let user1 = allUsers.first(where: { $0.id == user1ID }) else { return false }
        return user1.friendIDs.contains(user2ID)
    }

    func removeFriend(currentUserInitiatorID: UUID, friendToRemoveID: UUID) {
        guard currentUserInitiatorID != friendToRemoveID else {
            print("UserStore: Cannot remove self from friends.")
            return
        }

        var initiatorIndex: Int?
        var friendIndex: Int?

        if let idx = allUsers.firstIndex(where: { $0.id == currentUserInitiatorID }) {
            initiatorIndex = idx
        }
        if let idx = allUsers.firstIndex(where: { $0.id == friendToRemoveID }) {
            friendIndex = idx
        }

        if let initiatorIdx = initiatorIndex, allUsers.indices.contains(initiatorIdx) {
            if let removalIdx = allUsers[initiatorIdx].friendIDs.firstIndex(of: friendToRemoveID) {
                allUsers[initiatorIdx].friendIDs.remove(at: removalIdx)
                if currentUser?.id == currentUserInitiatorID {
                    currentUser?.friendIDs.removeAll(where: { $0 == friendToRemoveID })
                }
                print("UserStore: \(allUsers[initiatorIdx].username) removed friend ID \(friendToRemoveID).")
            } else {
                print("UserStore: \(allUsers[initiatorIdx].username) was not friends with ID \(friendToRemoveID).")
            }
        } else {
            print("UserStore: Error - Could not find initiator user \(currentUserInitiatorID) to remove friend.")
            return
        }

        if let friendIdx = friendIndex, allUsers.indices.contains(friendIdx) {
            if let removalIdx = allUsers[friendIdx].friendIDs.firstIndex(of: currentUserInitiatorID) {
                allUsers[friendIdx].friendIDs.remove(at: removalIdx)
                if currentUser?.id == friendToRemoveID {
                     currentUser?.friendIDs.removeAll(where: { $0 == currentUserInitiatorID })
                }
                print("UserStore: \(allUsers[friendIdx].username) removed friend ID \(currentUserInitiatorID) (mutual).")
            } else {
                print("UserStore: \(allUsers[friendIdx].username) was not friends with ID \(currentUserInitiatorID) (mutual).")
            }
        } else {
            print("UserStore: Error - Could not find friend user \(friendToRemoveID) for mutual removal.")
        }
    }
}
