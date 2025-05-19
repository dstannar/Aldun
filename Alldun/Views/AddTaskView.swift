import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.colorScheme) var colorScheme

    @State private var taskTitle = ""
    @State private var startDate = Date()
    @State private var dueDate = Date()
    @State private var selectedCategory: TaskType = .miscellaneous // RENAMED: from selectedTaskType for clarity
    @State private var notes = ""
    @State private var selectedPriority: Priority = .medium
    @State private var selectedCompletionStyle: TaskCompletionStyle = .singleImage

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Title").font(.headline)) {
                    TextField("Enter task title", text: $taskTitle)
                        .padding(.vertical, 5) // Add some padding to make it feel less cramped
                }

                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Due Date", selection: $dueDate, in: startDate..., displayedComponents: [.date, .hourAndMinute]) // Ensure due date is after start date
                }

                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(Priority.allCases) { priorityValue in
                            Text(priorityValue.rawValue).tag(priorityValue)
                        }
                    }

                    Picker("Completion Style", selection: $selectedCompletionStyle) {
                        ForEach(TaskCompletionStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                }
                
                Section(header: Text("Notes").font(.headline)) {
                    TextEditor(text: $notes)
                        .frame(height: 100) // Give it some default height
                        .cornerRadius(6) // Optional: to match other form field looks
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                                .opacity(notes.isEmpty ? 0.3 : 0) // Show border subtly or only when empty
                        )
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(colorScheme == .dark ? .white : .black) // Ensure visibility
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { // Keep save button in toolbar for consistency, or move it below form
                    Button("Create Task") {
                        saveTask()
                    }
                    .disabled(taskTitle.isEmpty)
                    .fontWeight(.bold) // Make it prominent
                }
            }
            .onAppear {
                print("AddTaskView onAppear: taskStore has \(taskStore.tasks.count) tasks.")
            }
        }
    }

    private func saveTask() {
        print("AddTaskView Save Button: Attempting to save task: \(taskTitle) of category: \(selectedCategory.rawValue), style: \(selectedCompletionStyle.rawValue)")
        
        guard let placeholderUserID = userStore.allUsers.first?.id else {
            print("AddTaskView Save Button: ERROR - No users available in UserStore to assign to Task.")
            // Optionally, show an alert to the user here
            return
        }

        // The startDate from the DatePicker is used for the task's startDate.
        // If completionStyle is .singleImage, this startDate might just be a general start time.
        // If completionStyle is .twoPhoto, this startDate is specifically for the first photo.
        // The dueDate is for the final deadline (completion photo for .twoPhoto, or the single photo).

        let newTask = Task(
            title: taskTitle,
            startDate: startDate, // Use the selected start date
            dueDate: dueDate,
            completionStyle: selectedCompletionStyle,
            taskType: selectedCategory,
            notes: notes.isEmpty ? nil : notes,
            priority: selectedPriority,
            userID: placeholderUserID
            // Other new fields like image data, timestamps, lateness flags will default to nil/false
        )
        taskStore.tasks.append(newTask)
        // scheduleNotification will use the task's properties (including completionStyle)
        // to determine the appropriate notifications.
        taskStore.scheduleNotification(for: newTask)
        print("AddTaskView Save Button: Task supposedly appended. Current tasks: \(taskStore.tasks.count)")
        
        dismiss() // Dismiss after saving
    }
}

struct BackendTestView: View {
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
        guard let url = URL(string: "http://127.0.0.1:8000/") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    backendMessage = "Error: \(error.localizedDescription)"
                }
            } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    backendMessage = "Backend: \(responseString)"
                }
            }
        }.resume()
    }
}
