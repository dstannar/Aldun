import SwiftUI
import Combine

struct TaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var navigationState: AppNavigationState
    @EnvironmentObject var userStore: UserStore
    @ObservedObject var calendarImporter: CalendarImporter

    @State private var selectedTask: Task?
    @State private var showingCompletionAlert = false
    @State private var showingAddTaskSheet = false
    
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var countdownActive = false
    @State private var timeRemaining = 30
    @State private var countdownTimerSubscription: AnyCancellable?
    @State private var requestedImageSource: UIImagePickerController.SourceType = .photoLibrary
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var todaysTasks: [Task] {
        taskStore.tasks.filter { task in
            Calendar.current.isDateInToday(task.dueDate) && !task.isCompleted && !task.isMissed
        }.sorted(by: { $0.dueDate < $1.dueDate })
    }

    private var completedTasks: [Task] {
        taskStore.tasks.filter { $0.isCompleted }
                       .sorted(by: { $0.dueDate > $1.dueDate })
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                List {
                    if !todaysTasks.isEmpty {
                        Section(header: Text("Today").font(.title2).bold()) {
                            ForEach(todaysTasks) { task in
                                TaskBubbleView(task: task, selectedTask: $selectedTask, showingCompletionAlert: $showingCompletionAlert)
                            }
                        }
                    } else {
                        Section(header: Text("Today").font(.title2).bold()) {
                            Text("No tasks for today. Add some!")
                                .foregroundColor(.gray)
                        }
                    }

                    if !completedTasks.isEmpty {
                        Section(header: Text("Completed").font(.title2).bold()) {
                            ForEach(completedTasks) { task in
                                TaskBubbleView(task: task, selectedTask: .constant(nil), showingCompletionAlert: .constant(false))
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Alldun")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTaskSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .onAppear {
                print("TaskView onAppear: taskStore has \(taskStore.tasks.count) tasks.")
                _ = self.calendarImporter
                print("TaskView onAppear: Successfully accessed calendarImporter instance.")
                checkForNotificationTask()
            }
            .onChange(of: navigationState.taskIDToOpen) { _, newTaskIDToOpen in
                 if newTaskIDToOpen != nil {
                    checkForNotificationTask()
                 }
            }
            .onChange(of: selectedImage) { _, newImage in
                handleImageSelection(newImage: newImage)
            }
            .alert("Complete Task?", isPresented: $showingCompletionAlert) {
                Button("Cancel", role: .cancel) {
                    print("TaskView Alert: Cancelled.")
                    selectedTask = nil
                }
                Button("From Photo Gallery") {
                    print("TaskView Alert: 'From Photo Gallery' pressed.")
                    if let task = selectedTask {
                        self.requestedImageSource = .photoLibrary
                        startCountdown(for: task)
                    }
                }
                Button("Use Live Camera") {
                    print("TaskView Alert: 'Use Live Camera' pressed.")
                    if let task = selectedTask {
                        self.requestedImageSource = .camera
                        startCountdown(for: task)
                    }
                }
            } message: {
                if let task = selectedTask {
                    Text("Would you like to mark '\(task.title)' as complete?")
                } else {
                    Text("Would you like to complete this task?")
                }
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: {
                let _ = print("TaskView DEBUG: .sheet content closure executed. showingImagePicker is \($showingImagePicker.wrappedValue), countdownActive is \(self.countdownActive)")
                if self.countdownActive {
                    print("ImagePicker sheet dismissed by user while countdown active for task: \(selectedTask?.title ?? "Unknown"). Marking as missed.")
                    self.stopCountdown(missed: true, taskWasActuallySelected: selectedTask)
                }
            }) {
                VStack {
                    if self.countdownActive {
                        Text("Time Remaining: \(self.timeRemaining)s")
                            .font(.headline)
                            .padding()
                            .foregroundColor(self.timeRemaining <= 10 ? .red : .primary)
                    }
                    ImagePicker(selectedImage: self.$selectedImage, sourceType: self.requestedImageSource)
                }
            }
            .sheet(isPresented: $showingAddTaskSheet) {
                AddTaskView()
            }
        }
    }

    private func startCountdown(for task: Task) {
        print("TaskView DEBUG: startCountdown for task '\(task.title)'")
        self.selectedTask = task
        self.timeRemaining = 30
        self.countdownActive = true
        print("TaskView DEBUG: Setting showingImagePicker to true. Current value before set: \(self.showingImagePicker)")
        self.showingImagePicker = true
        print("TaskView DEBUG: showingImagePicker is now \(self.showingImagePicker). Sheet should appear.")


        self.countdownTimerSubscription?.cancel()
        self.countdownTimerSubscription = self.timerPublisher
            .sink { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    print("Time remaining for \(task.title): \(self.timeRemaining)s")
                } else {
                    print("Countdown finished for task: \(task.title). Marking as missed.")
                    self.stopCountdown(missed: true, taskWasActuallySelected: self.selectedTask)
                }
            }
    }

    private func stopCountdown(missed: Bool, taskWasActuallySelected: Task?) {
        print("Stopping countdown for task: \(taskWasActuallySelected?.title ?? "N/A"). Missed: \(missed)")
        self.countdownTimerSubscription?.cancel()
        self.countdownTimerSubscription = nil
        self.countdownActive = false
        
        if self.showingImagePicker {
            print("TaskView DEBUG: stopCountdown is setting showingImagePicker to false.")
            self.showingImagePicker = false
        }

        if missed, let taskID = taskWasActuallySelected?.id, let index = taskStore.tasks.firstIndex(where: { $0.id == taskID }) {
            if !taskStore.tasks[index].isCompleted {
                taskStore.tasks[index].isMissed = true
                print("Task '\(taskStore.tasks[index].title)' marked as missed in store.")
            }
        }
    }
    
    private func handleImageSelection(newImage: UIImage?) {
        guard let image = newImage else {
            if self.countdownActive, let currentSelectedTask = self.selectedTask {
                self.stopCountdown(missed: true, taskWasActuallySelected: currentSelectedTask)
            }
            return
        }

        let taskForCompletion = self.selectedTask

        if self.countdownActive {
            self.stopCountdown(missed: false, taskWasActuallySelected: taskForCompletion)
        }

        if let taskToComplete = taskForCompletion {
            self.completeTask(task: taskToComplete, with: image)
        }
        
        self.selectedImage = nil
        self.selectedTask = nil
    }
    
    private func completeTask(task: Task, with image: UIImage) {
        if let index = taskStore.tasks.firstIndex(where: { $0.id == task.id }) {
            taskStore.tasks[index].isCompleted = true
            taskStore.tasks[index].isMissed = false
            taskStore.cancelNotification(for: taskStore.tasks[index])
            
            guard let placeholderUserID = userStore.allUsers.first?.id else {
                print("TaskView completeTask (with image): ERROR - No user ID available from allUsers for FeedPost.")
                return
            }

            let post = FeedPost(userID: placeholderUserID, task: task.title, image: image, liked: false, timestamp: Date())
            feedStore.posts.insert(post, at: 0)
            print("TaskView completeTask (with image): Feed post created for '\(task.title)' by user ID \(placeholderUserID).")
        } else {
            print("TaskView completeTask (with image): ERROR - Task '\(task.title)' not found in store for completion.")
        }
    }
    
    private func checkForNotificationTask() {
        guard let taskID = navigationState.taskIDToOpen else { return }
        if let taskToOpen = taskStore.tasks.first(where: { $0.id == taskID && !$0.isCompleted && !$0.isMissed }) {
            selectedTask = taskToOpen
            showingCompletionAlert = true
            navigationState.taskIDToOpen = nil
        } else if taskStore.tasks.first(where: { $0.id == taskID }) != nil {
            navigationState.taskIDToOpen = nil
        } else {
            navigationState.taskIDToOpen = nil
        }
    }
}

struct TaskBubbleView: View {
    let task: Task
    @Binding var selectedTask: Task?
    @Binding var showingCompletionAlert: Bool

    @EnvironmentObject var calendarImporter: CalendarImporter
    @Environment(\.openURL) var openURL

    @State private var showingCalendarExportAlert = false
    @State private var calendarExportAlertTitle = ""
    @State private var calendarExportAlertMessage = ""
    @State private var showingInvalidLinkAlert = false

    var body: some View {
        let _ = print("TaskBubbleView BODY: Rendering task '\(task.title)', isCompleted: \(task.isCompleted), isMissed: \(task.isMissed). Link: \(task.linkURLString ?? "None")")

        HStack(spacing: 8) {
            Text(task.title)
                .strikethrough(task.isCompleted, color: .gray)
                .foregroundColor(task.isCompleted ? .gray : (task.isMissed ? .red : .primary))
            
            Spacer()

            if let urlString = task.linkURLString, let url = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(url) || urlString.lowercased().starts(with: "http") {
                    Button {
                        print("Attempting to open URL: \(url)")
                        openURL(url) { accepted in
                            if !accepted {
                                print("Failed to accept URL: \(url)")
                            }
                        }
                    } label: {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            showingInvalidLinkAlert = true
                        }
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            print("TaskBubbleView .onTapGesture (on HStack): Task '\(task.title)' was tapped.")
            if !task.isCompleted && !task.isMissed {
                print("TaskBubbleView .onTapGesture (on HStack): Condition met, setting selectedTask and showingCompletionAlert.")
                selectedTask = task
                showingCompletionAlert = true
            } else {
                print("TaskBubbleView .onTapGesture (on HStack): Tap on completed/missed task, no action.")
            }
        }
        .swipeActions(edge:.leading, allowsFullSwipe: false) {
            if !task.isCompleted && !task.isMissed {
                Button {
                    exportToCalendar()
                } label: {
                    Label("Export to Calendar", systemImage: "calendar.badge.plus")
                }
                .tint(.blue)
            }
        }
        .alert(isPresented: $showingCalendarExportAlert) {
            Alert(title: Text(calendarExportAlertTitle), message: Text(calendarExportAlertMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Invalid Link", isPresented: $showingInvalidLinkAlert) {
            Button("OK") {}
        } message: {
            Text("The link provided for this task ('\(task.linkURLString ?? "")') does not appear to be a valid web URL that can be opened.")
        }
    }

    private func exportToCalendar() {
        print("TaskBubbleView: exportToCalendar() called for task '\(task.title)'")
        calendarImporter.requestAccess { granted, error in
            if let error = error {
                self.calendarExportAlertTitle = "Calendar Error"
                if case CalendarImportError.accessDenied = error {
                    self.calendarExportAlertMessage = "Calendar access was denied. Please enable it in Settings."
                } else {
                    self.calendarExportAlertMessage = "Could not access calendar: \(error.localizedDescription)"
                }
                self.showingCalendarExportAlert = true
                return
            }

            if granted {
                calendarImporter.exportTaskToCalendar(task: task) { success, exportError in
                    if success {
                        self.calendarExportAlertTitle = "Exported!"
                        self.calendarExportAlertMessage = "'\(task.title)' has been added to your calendar."
                    } else {
                        self.calendarExportAlertTitle = "Export Failed"
                        self.calendarExportAlertMessage = "Could not add '\(task.title)' to calendar. \(exportError?.localizedDescription ?? "Unknown error")"
                    }
                    self.showingCalendarExportAlert = true
                }
            } else {
                self.calendarExportAlertTitle = "Access Denied"
                self.calendarExportAlertMessage = "Calendar access was not granted. Please enable it in Settings."
                self.showingCalendarExportAlert = true
            }
        }
    }
}
