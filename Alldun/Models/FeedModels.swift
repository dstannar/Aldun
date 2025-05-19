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
    let id: UUID // Ensured this is UUID
    let taskID: UUID
    let userID: User.ID
    let taskTitle: String
    let completionStyle: TaskCompletionStyle

    var startImage: UIImage?
    var startImageTimestamp: Date?
    var wasStartImageLate: Bool?

    var completionImage: UIImage?
    var completionImageTimestamp: Date?
    var wasCompletionLate: Bool?

    var liked: Bool
    let timestamp: Date
    var comments: [Comment]

    var isAwaitingCompletionImage: Bool {
        return completionStyle == .twoPhoto && startImage != nil && completionImage == nil
    }

    var isOverallLate: Bool {
        return wasStartImageLate == true || wasCompletionLate == true
    }

    init(id: UUID = UUID(),
         taskID: UUID,
         userID: User.ID,
         taskTitle: String,
         completionStyle: TaskCompletionStyle,
         startImage: UIImage? = nil,
         startImageTimestamp: Date? = nil,
         wasStartImageLate: Bool? = nil,
         completionImage: UIImage? = nil,
         completionImageTimestamp: Date? = nil,
         wasCompletionLate: Bool? = nil,
         liked: Bool = false,
         timestamp: Date = Date(),
         comments: [Comment] = [],
         _wasOverallLate_ignored: Bool? = nil // Parameter name indicates it's ignored
    ) {
        self.id = id
        self.taskID = taskID
        self.userID = userID
        self.taskTitle = taskTitle
        self.completionStyle = completionStyle
        self.startImage = startImage
        self.startImageTimestamp = startImageTimestamp
        self.wasStartImageLate = wasStartImageLate
        self.completionImage = completionImage
        self.completionImageTimestamp = completionImageTimestamp
        self.wasCompletionLate = wasCompletionLate
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

    func addComment(to postTaskID: UUID, by userID: User.ID, text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("FeedStore: Cannot add empty comment.")
            return
        }

        if let index = posts.firstIndex(where: { $0.taskID == postTaskID }) {
            let newComment = Comment(userID: userID, text: text)
            posts[index].comments.append(newComment)
            print("FeedStore: Added comment '\(text)' by \(userID) to post for task \(postTaskID). New comment count: \(posts[index].comments.count)")
        } else {
            print("FeedStore: Error - Could not find post for task ID \(postTaskID) to add comment.")
        }
    }

    func toggleLike(for postTaskID: UUID) {
        if let index = posts.firstIndex(where: { $0.taskID == postTaskID }) {
            posts[index].liked.toggle()
        } else {
            print("FeedStore: Error - Could not find post for task ID \(postTaskID) to toggle like.")
        }
    }

    func createOrUpdatePostForStartImage(task: Task, image: UIImage, timestamp: Date, wasStartImageLate: Bool?) {
        if let index = posts.firstIndex(where: { $0.taskID == task.id }) {
            posts[index].startImage = image
            posts[index].startImageTimestamp = timestamp
            posts[index].wasStartImageLate = wasStartImageLate
            print("FeedStore: Updated existing feed post for task \(task.id) with new start image. Start late: \(wasStartImageLate ?? false)")
        } else {
            let newPost = FeedPost(
                taskID: task.id,
                userID: task.userID,
                taskTitle: task.title,
                completionStyle: task.completionStyle,
                startImage: image,
                startImageTimestamp: timestamp,
                wasStartImageLate: wasStartImageLate,
                timestamp: timestamp
            )
            posts.insert(newPost, at: 0)
            print("FeedStore: Created new feed post for task \(task.id) with start image. Start late: \(wasStartImageLate ?? false)")
        }
    }

    func updatePostWithCompletionImage(taskID: UUID, image: UIImage, timestamp: Date, wasCompletionImageLate: Bool?) {
        if let index = posts.firstIndex(where: { $0.taskID == taskID }) {
            posts[index].completionImage = image
            posts[index].completionImageTimestamp = timestamp
            posts[index].wasCompletionLate = wasCompletionImageLate
            print("FeedStore: Updated feed post for task \(taskID) with completion image. Completion late: \(wasCompletionImageLate ?? false)")
        } else {
            print("FeedStore: Error - Could not find feed post for task \(taskID) to add completion image.")
        }
    }
}
