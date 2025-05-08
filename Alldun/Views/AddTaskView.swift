import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var userStore: UserStore
    @State private var taskTitle = ""
    @State private var dueDate = Date()
    @State private var selectedTaskType: TaskType = .miscellaneous
    @State private var linkURLString = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Task Title", text: $taskTitle)
                DatePicker("Due Date", selection: $dueDate, in: Date()...)
                
                Picker("Task Type", selection: $selectedTaskType) {
                    ForEach(TaskType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)

                TextField("Link (optional)", text: $linkURLString)
                    .keyboardType(.URL)
                    .autocapitalization(.none)

                Button("Save Task") {
                    print("AddTaskView Save Button: Attempting to save task: \(taskTitle) of type: \(selectedTaskType.rawValue)")
                    
                    guard let placeholderUserID = userStore.allUsers.first?.id else {
                        print("AddTaskView Save Button: ERROR - No users available in UserStore to assign to Task.")
                        return
                    }

                    let validatedLink = linkURLString.trimmingCharacters(in: .whitespacesAndNewlines)
                    let linkToSave = validatedLink.isEmpty ? nil : validatedLink
                    
                    let newTask = Task(
                        title: taskTitle,
                        dueDate: dueDate,
                        taskType: selectedTaskType,
                        userID: placeholderUserID,
                        linkURLString: linkToSave
                    )
                    taskStore.tasks.append(newTask)
                    taskStore.scheduleNotification(for: newTask)
                    print("AddTaskView Save Button: Task supposedly appended. Link: \(linkToSave ?? "None"). Current tasks: \(taskStore.tasks.count)")
                    
                    taskTitle = ""
                    dueDate = Date()
                    selectedTaskType = .miscellaneous
                    linkURLString = ""
                }
                .disabled(taskTitle.isEmpty)
            }
            .navigationTitle("Add Task")
            .onAppear {
                print("AddTaskView onAppear: taskStore has \(taskStore.tasks.count) tasks.")
            }
        }
    }
}
