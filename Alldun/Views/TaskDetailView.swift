import SwiftUI

struct TaskDetailView: View {
    let task: Task
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL

    private static var fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        List {
            Section {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Section(header: Text("Details")) {
                if let startDate = task.startDate {
                    HStack {
                        Text("Starts")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(startDate, formatter: Self.fullDateFormatter)
                    }
                }
                HStack {
                    Text("Due")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(task.dueDate, formatter: Self.fullDateFormatter)
                }
                HStack {
                    Text("Category")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(task.taskType.rawValue)
                }
                HStack {
                    Text("Priority")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(task.priority.rawValue)
                        .foregroundColor(priorityColor(task.priority))
                }
            }

            if let notes = task.notes, !notes.isEmpty {
                Section(header: Text("Notes")) {
                    Text(notes)
                }
            }

            if let linkString = task.linkURLString, let url = URL(string: linkString) {
                Section(header: Text("Link")) {
                    Button(action: {
                        openURL(url)
                    }) {
                        Text(linkString)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            
            // Placeholder for future actions like "Complete Task" or "Edit"
            // Section {
            //     Button("Mark as Complete") {
            //         // Action to complete task
            //     }
            //     .disabled(task.isCompleted || task.isMissed)
            // }
        }
        .listStyle(InsetGroupedListStyle()) // Or .plain for a simpler look
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }
}

//struct TaskDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            TaskDetailView(task: Task(
//                title: "Sample High Priority Task",
//                startDate: Calendar.current.date(byAdding: .hour, value: -1, to: Date()),
//                dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!,
//                taskType: .exercise,
//                notes: "These are some detailed notes for the sample task. It should be quite descriptive and potentially long to test text wrapping and display.",
//                priority: .high,
//                userID: UUID(), // Dummy user ID
//                linkURLString: "https://www.apple.com"
//            ))
//        }
//    }
//}
