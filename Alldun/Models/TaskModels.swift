import Foundation
import Combine
import UserNotifications
import UIKit

enum TaskCompletionStyle: String, CaseIterable, Identifiable, Codable {
    case singleImage = "Single Image" // For tasks requiring one image
    case twoPhoto = "Two Photos"    // For tasks requiring a start and completion image

    var id: String { self.rawValue }
}

enum TaskType: String, CaseIterable, Identifiable, Codable {
    case exercise = "Exercise"
    case homework = "Homework"
    case study = "Study"
    case miscellaneous = "Miscellaneous"

    var id: String { self.rawValue }
}

enum Priority: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { self.rawValue }
}

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var startDate: Date? // For two-photo, this is when the "start" image is expected
    var dueDate: Date    // For two-photo, this is when the "completion" image is expected / For single, when the only image is expected
    
    var completionStyle: TaskCompletionStyle

    var startImageData: Data?
    var startImageTimestamp: Date?
    var completionImageData: Data?
    var completionImageTimestamp: Date?

    var wasStartUploadLate: Bool?       // Relevant for twoPhoto style
    var wasCompletionUploadLate: Bool?  // Relevant for both styles if applicable, or just twoPhoto

    var isCompleted: Bool = false
    var isMissed: Bool = false

    var taskType: TaskType
    var notes: String?
    var priority: Priority
    let userID: User.ID
    var linkURLString: String?
    
    var isInProgress: Bool {
        if completionStyle == .twoPhoto && startImageData != nil && completionImageData == nil && !isCompleted && !isMissed {
            return true
        }
        return false
    }

    init(id: UUID = UUID(),
         title: String,
         startDate: Date? = nil, // Becomes more significant for two-photo
         dueDate: Date,
         completionStyle: TaskCompletionStyle = .singleImage, // Default to single image
         startImageData: Data? = nil,
         startImageTimestamp: Date? = nil,
         completionImageData: Data? = nil,
         completionImageTimestamp: Date? = nil,
         wasStartUploadLate: Bool? = nil,
         wasCompletionUploadLate: Bool? = nil,
         isCompleted: Bool = false, // Initial state, will be updated by logic
         isMissed: Bool = false,   // Initial state, will be updated by logic
         taskType: TaskType = .miscellaneous,
         notes: String? = nil,
         priority: Priority = .medium,
         userID: User.ID,
         linkURLString: String? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.dueDate = dueDate
        self.completionStyle = completionStyle
        self.startImageData = startImageData
        self.startImageTimestamp = startImageTimestamp
        self.completionImageData = completionImageData
        self.completionImageTimestamp = completionImageTimestamp
        self.wasStartUploadLate = wasStartUploadLate
        self.wasCompletionUploadLate = wasCompletionUploadLate
        self.isCompleted = isCompleted
        self.isMissed = isMissed
        self.taskType = taskType
        self.notes = notes
        self.priority = priority
        self.userID = userID
        self.linkURLString = linkURLString
        
        // Recalculate completion status based on provided image data on init
        self.updateStatusBasedOnImageData()
    }

    mutating func updateStatusBasedOnImageData() {
        if self.completionStyle == .singleImage {
            if self.startImageData != nil {
                self.isCompleted = true
                self.isMissed = false
            } else {
                // Missed status for singleImage would be determined by time + lack of image
                // For now, just init based on image presence. External logic will set isMissed by date.
                 self.isCompleted = false
            }
        } else { // .twoPhoto
            if self.startImageData != nil && self.completionImageData != nil {
                self.isCompleted = true
                self.isMissed = false
            } else {
                // Missed status for twoPhoto is more complex (missed start, or missed completion)
                // External logic will set isMissed.
                 self.isCompleted = false
            }
        }
    }
}

class TaskStore: ObservableObject {
    @Published var tasks: [Task] = [] {
        didSet {
            print("--- TaskStore: tasks array changed. New count: \(tasks.count) ---")
            if let lastTask = tasks.last {
                print("--- TaskStore: Last task added/changed: \(lastTask.title) ---")
            }
        }
    }

    // scheduleNotification and cancelNotification will need updates later
    // to handle the new logic for two-photo tasks (e.g., different messages,
    // potentially different notification types for "upload completion photo").
    // For now, the structure remains, but their internal logic will change.

    func scheduleNotification(for task: Task) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        // Logic will adapt based on task.completionStyle and its current state (e.g., isInProgress)
        
        // Example: Notification for Start Image (if two-photo style and start date exists)
        if task.completionStyle == .twoPhoto, let startDate = task.startDate, task.startImageData == nil {
            let startContent = UNMutableNotificationContent()
            startContent.title = "Time to start: \(task.title)"
            startContent.body = "Upload your 'before' picture!"
            startContent.sound = .default
            // Differentiate notification type if needed for specific handling
            startContent.userInfo = ["taskID": task.id.uuidString, "notificationType": "start_image_prompt"]
            
            let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
            let startTrigger = UNCalendarNotificationTrigger(dateMatching: startComponents, repeats: false)
            let startRequestIdentifier = task.id.uuidString + "_start_image"
            let startRequest = UNNotificationRequest(identifier: startRequestIdentifier, content: startContent, trigger: startTrigger)

            center.add(startRequest) { error in
                if let error = error {
                    print("Error scheduling start image notification for task \(task.title): \(error.localizedDescription)")
                } else {
                    print("Successfully scheduled start image notification for task \(task.title) at \(startDate)")
                }
            }
        }

        // Notification for Due Date / Completion Image
        // This notification's content and timing might change based on whether it's a single image task
        // or a two-photo task that's already in progress.
        let dueContent = UNMutableNotificationContent()
        if task.completionStyle == .twoPhoto {
            if task.isInProgress {
                dueContent.title = "Task Due: \(task.title)"
                dueContent.body = "Time to upload your 'after' picture!"
            } else if task.startImageData == nil && task.startDate == nil { // Two-photo task but no explicit start time, due date is for start.
                 dueContent.title = "Task Due: \(task.title)"
                 dueContent.body = "Upload your 'before' picture for \(task.title)!"
            } else if task.startImageData == nil && task.startDate != nil { // Start date defined, but this is the due date reminder
                 dueContent.title = "Reminder: \(task.title)"
                 dueContent.body = "Don't forget to start and complete your task."
            } else { // Should not happen if isInProgress is handled
                dueContent.title = "Task Update: \(task.title)"
                dueContent.body = "Check the status of your task."
            }
        } else { // singleImage style
            dueContent.title = "Task Due: \(task.title)"
            dueContent.body = "It's time to complete your task and upload a picture!"
        }
        dueContent.sound = .default
        // Differentiate notification type
        dueContent.userInfo = ["taskID": task.id.uuidString, "notificationType": task.isInProgress ? "completion_image_prompt" : "due_prompt"]

        let dueComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
        let dueTrigger = UNCalendarNotificationTrigger(dateMatching: dueComponents, repeats: false)
        let dueRequestIdentifier = task.id.uuidString + "_due_completion" // More specific ID
        let dueRequest = UNNotificationRequest(identifier: dueRequestIdentifier, content: dueContent, trigger: dueTrigger)

        center.add(dueRequest) { error in
            if let error = error {
                print("Error scheduling due/completion notification for task \(task.title): \(error.localizedDescription)")
            } else {
                print("Successfully scheduled due/completion notification for task \(task.title) at \(task.dueDate)")
            }
        }
    }

    func cancelNotification(for task: Task) {
        // Updated identifiers to match new scheduling logic
        let identifiersToRemove = [
            task.id.uuidString + "_start_image",
            task.id.uuidString + "_due_completion",
            // Keep old ones for transition if any tasks were scheduled with them
            task.id.uuidString + "_start",
            task.id.uuidString + "_due",
            task.id.uuidString
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        print("Cancelled notifications for task \(task.title) (identifiers: \(identifiersToRemove.joined(separator: ", ")))")
    }

    // These will be more fleshed out later but are placeholders for the store's responsibilities.
    // For example:
    // func uploadStartImage(for taskID: UUID, imageData: Data, timestamp: Date, isLate: Bool) { ... }
    // func uploadCompletionImage(for taskID: UUID, imageData: Data, timestamp: Date, isLate: Bool) { ... }
}
