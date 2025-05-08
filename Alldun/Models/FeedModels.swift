import SwiftUI 
import UIKit 
import Combine 

struct Comment: Identifiable, Hashable { 
    let id: UUID
    let userID: User.ID
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), userID: User.ID, text: String, timestamp: Date = Date()) {
        self.id = id
        self.userID = userID
        self.text = text
        self.timestamp = timestamp
    }
}

struct FeedPost: Identifiable {
    let id: UUID
    let userID: User.ID 
    let task: String
    let image: UIImage
    var liked: Bool
    let timestamp: Date 
    var comments: [Comment] 

    init(id: UUID = UUID(), userID: User.ID, task: String, image: UIImage, liked: Bool = false, timestamp: Date = Date(), comments: [Comment] = []) { 
        self.id = id
        self.userID = userID
        self.task = task
        self.image = image
        self.liked = liked
        self.timestamp = timestamp
        self.comments = comments 
    }
}

class FeedStore: ObservableObject {
    @Published var posts: [FeedPost] = []
    
    init() {
        self.posts = []
    }

    func addComment(to postID: UUID, by userID: User.ID, text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("FeedStore: Cannot add empty comment.")
            return
        }

        if let index = posts.firstIndex(where: { $0.id == postID }) {
            let newComment = Comment(userID: userID, text: text)
            posts[index].comments.append(newComment)
            print("FeedStore: Added comment '\(text)' by \(userID) to post \(postID). New comment count: \(posts[index].comments.count)")
        } else {
            print("FeedStore: Error - Could not find post with ID \(postID) to add comment.")
        }
    }

    func toggleLike(for postID: UUID) {
        if let index = posts.firstIndex(where: { $0.id == postID }) {
            posts[index].liked.toggle()
        }
    }
}
