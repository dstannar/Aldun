import Foundation
import Combine
import UserNotifications

enum TaskType: String, CaseIterable, Identifiable, Codable {
    case exercise = "Exercise"
    case homework = "Homework"
    case study = "Study"
    case miscellaneous = "Miscellaneous"

    var id: String { self.rawValue }
}

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var dueDate: Date
    var isCompleted: Bool = false
    var isMissed: Bool = false
    var taskType: TaskType
    let userID: User.ID
    var linkURLString: String?
    
    init(id: UUID = UUID(), title: String, dueDate: Date, isCompleted: Bool = false, isMissed: Bool = false, taskType: TaskType = .miscellaneous, userID: User.ID, linkURLString: String? = nil) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.isMissed = isMissed
        self.taskType = taskType
        self.userID = userID
        self.linkURLString = linkURLString
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

    func scheduleNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "Task Due!"
        content.body = "It's time to complete your task: \(task.title)"
        content.sound = .default
        content.userInfo = ["taskID": task.id.uuidString]

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification for task \(task.title): \(error.localizedDescription)")
            } else {
                print("Successfully scheduled notification for task \(task.title) at \(task.dueDate)")
            }
        }
    }

    func cancelNotification(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
        print("Cancelled notification for task \(task.title)")
    }
}
