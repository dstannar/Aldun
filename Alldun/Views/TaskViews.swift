import SwiftUI
import Combine

struct TaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var navigationState: AppNavigationState
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var calendarImporter: CalendarImporter
    @Environment(\.colorScheme) var colorScheme

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

    @State private var taskForDetailNavigation: Task?
    @State private var isDetailNavigationActive: Bool = false

    @State private var currentImageCapturePurpose: ImageCapturePurpose = .singleOrStart

    enum ImageCapturePurpose {
        case singleOrStart
        case completion
    }

    private var todaysTasks: [Task] {
        var result: [Task] = []
        for task in taskStore.tasks {
            if !task.isCompleted && !task.isMissed &&
               (Calendar.current.isDateInToday(task.dueDate) || (task.isInProgress && Calendar.current.isDateInToday(task.dueDate))) {
                result.append(task)
            }
        }
        return result.sorted(by: { $0.dueDate < $1.dueDate })
    }

    private var completedTasks: [Task] {
        var result: [Task] = []
        for task in taskStore.tasks {
            if task.isCompleted {
                result.append(task)
            }
        }
        return result.sorted(by: { $0.dueDate > $1.dueDate })
    }
    
    private var inProgressTasks: [Task] {
        var result: [Task] = []
        for task in taskStore.tasks {
            if task.isInProgress && !task.isCompleted && !task.isMissed {
                result.append(task)
            }
        }
        return result.sorted(by: { $0.dueDate < $1.dueDate })
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("ALLDUN")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)

                Button(action: {
                    showingAddTaskSheet = true
                }) {
                    Text("Add Task")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)


                List {
                    if !todaysTasks.isEmpty {
                        Section {
                            ForEach(todaysTasks) { task in
                                TaskBubbleView(
                                    task: task,
                                    selectedTask: $selectedTask,
                                    showingCompletionAlert: $showingCompletionAlert,
                                    onShowDetails: { detailTask in
                                        self.taskForDetailNavigation = detailTask
                                        if self.taskForDetailNavigation != nil {
                                            self.isDetailNavigationActive = true
                                        }
                                    }
                                )
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                            }
                        } header: {
                            HStack {
                                Text("Today")
                                    .font(.title.bold())
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.top)
                            .padding(.leading)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                        }
                        
                    } else if todaysTasks.isEmpty && inProgressTasks.isEmpty {
                        Section {
                            Text("No tasks for today. Add some!")
                                .foregroundColor(.gray)
                                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .listRowInsets(EdgeInsets())
                        } header: {
                            HStack {
                                Text("Today")
                                    .font(.title.bold())
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.top)
                            .padding(.leading)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                        }
                    }

                    if !inProgressTasks.isEmpty {
                        Section {
                            ForEach(inProgressTasks) { task in
                                TaskBubbleView(
                                    task: task,
                                    selectedTask: $selectedTask,
                                    showingCompletionAlert: $showingCompletionAlert,
                                    onShowDetails: { detailTask in
                                        self.taskForDetailNavigation = detailTask
                                        if self.taskForDetailNavigation != nil {
                                            self.isDetailNavigationActive = true
                                        }
                                    }
                                )
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                            }
                        } header: {
                             HStack {
                                Text("In Progress")
                                    .font(.title.bold())
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.top)
                            .padding(.leading)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                        }
                    }

                    if !completedTasks.isEmpty {
                        Section {
                            ForEach(completedTasks) { task in
                                TaskBubbleView(
                                    task: task,
                                    selectedTask: .constant(nil),
                                    showingCompletionAlert: .constant(false),
                                    onShowDetails: { detailTask in
                                        self.taskForDetailNavigation = detailTask
                                        if self.taskForDetailNavigation != nil {
                                            self.isDetailNavigationActive = true
                                        }
                                    }
                                )
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                            }
                        } header: {
                            HStack {
                                Text("Completed")
                                    .font(.title2.bold())
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.top)
                            .padding(.leading)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { }
            .onAppear {
                print("TaskView onAppear: taskStore has \(taskStore.tasks.count) tasks.")
                _ = self.calendarImporter
                print("TaskView onAppear: Successfully accessed calendarImporter instance.")
                checkForNotificationTask(isDirectPhotoFlow: false)
            }
            .onChange(of: navigationState.taskIDToOpen) { _, newTaskIDToOpen in
                 if newTaskIDToOpen != nil {
                    if navigationState.triggerPhotoFlowForTaskID != newTaskIDToOpen {
                         checkForNotificationTask(isDirectPhotoFlow: false)
                    }
                 }
            }
            .onChange(of: navigationState.triggerPhotoFlowForTaskID) { _, newPhotoTaskID in
                if let taskID = newPhotoTaskID {
                    print("TaskView: triggerPhotoFlowForTaskID changed to \(taskID)")
                    if let taskToInteract = taskStore.tasks.first(where: { $0.id == taskID && !$0.isCompleted && !$0.isMissed }) {
                        print("TaskView: Found task '\(taskToInteract.title)' for notification-triggered photo flow.")
                        self.requestedImageSource = .photoLibrary
                        if taskToInteract.completionStyle == .twoPhoto {
                            if taskToInteract.startImageData == nil {
                                self.currentImageCapturePurpose = .singleOrStart
                                print("TaskView: Setting purpose to .singleOrStart for task \(taskToInteract.title)")
                            } else if taskToInteract.completionImageData == nil {
                                self.currentImageCapturePurpose = .completion
                                print("TaskView: Setting purpose to .completion for task \(taskToInteract.title)")
                            } else {
                                print("TaskView: Task \(taskToInteract.title) is two-photo but seems to have both images; notification flow unexpected.")
                                DispatchQueue.main.async { navigationState.triggerPhotoFlowForTaskID = nil }
                                return
                            }
                        } else {
                            self.currentImageCapturePurpose = .singleOrStart
                            print("TaskView: Setting purpose to .singleOrStart for single-image task \(taskToInteract.title)")
                        }
                        startCountdown(for: taskToInteract)
                    } else {
                        print("TaskView: Task for photo flow with ID \(taskID) not found or already completed/missed.")
                    }
                    DispatchQueue.main.async {
                        navigationState.triggerPhotoFlowForTaskID = nil
                        if navigationState.taskIDToOpen == taskID {
                            navigationState.taskIDToOpen = nil
                        }
                    }
                }
            }
            .onChange(of: selectedImage) { _, newImage in
                handleImageSelection(newImage: newImage)
            }
            .alert(alertTitle, isPresented: $showingCompletionAlert) {
                Button("Cancel", role: .cancel) {
                    selectedTask = nil
                }

                if let task = selectedTask, !task.isCompleted, !task.isMissed {
                    Button("From Photo Gallery") {
                        if let currentTask = selectedTask {
                            self.requestedImageSource = .photoLibrary
                            if currentTask.completionStyle == .twoPhoto && currentTask.startImageData != nil && currentTask.completionImageData == nil {
                                self.currentImageCapturePurpose = .completion
                            } else {
                                self.currentImageCapturePurpose = .singleOrStart
                            }
                            startCountdown(for: currentTask)
                        }
                    }
                    Button("Use Live Camera") {
                        if let currentTask = selectedTask {
                            self.requestedImageSource = .camera
                            if currentTask.completionStyle == .twoPhoto && currentTask.startImageData != nil && currentTask.completionImageData == nil {
                                self.currentImageCapturePurpose = .completion
                            } else {
                                self.currentImageCapturePurpose = .singleOrStart
                            }
                            startCountdown(for: currentTask)
                        }
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: {
                let _ = print("TaskView DEBUG: .sheet content closure executed. showingImagePicker is \($showingImagePicker.wrappedValue), countdownActive is \(self.countdownActive)")
                if self.countdownActive {
                    print("ImagePicker sheet dismissed by user while countdown active for task: \(selectedTask?.title ?? "Unknown"). Marking as missed for this step.")
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
            .navigationDestination(isPresented: $isDetailNavigationActive) {
                if let taskToDetail = taskForDetailNavigation {
                    TaskDetailView(task: taskToDetail)
                } else {
                    Text("Error: Task details not available.")
                }
            }
        }
    }

    private var alertTitle: String {
        guard let task = selectedTask else { return "Complete Task?" }
        if task.isCompleted || task.isMissed { return "Task Status" }

        switch task.completionStyle {
        case .singleImage:
            return "Complete Task?"
        case .twoPhoto:
            if task.startImageData == nil {
                return "Upload Start Photo?"
            } else if task.completionImageData == nil {
                return "Upload Completion Photo?"
            }
        }
        return "Task Action"
    }

    private var alertMessage: String {
        guard let task = selectedTask else { return "Would you like to complete this task?" }
        if task.isCompleted { return "'\(task.title)' is already completed." }
        if task.isMissed { return "'\(task.title)' was missed." }

        switch task.completionStyle {
        case .singleImage:
            return "Add a photo to complete '\(task.title)'."
        case .twoPhoto:
            if task.startImageData == nil {
                return "Upload the 'before' photo for '\(task.title)'."
            } else if task.completionImageData == nil {
                return "Upload the 'after' photo for '\(task.title)'."
            }
        }
        return "What would you like to do with '\(task.title)'?"
    }

    private func startCountdown(for task: Task) {
        print("TaskView DEBUG: startCountdown for task '\(task.title)', purpose: \(self.currentImageCapturePurpose)")
        self.selectedTask = task
        self.timeRemaining = 30
        self.countdownActive = true
        self.showingImagePicker = true

        self.countdownTimerSubscription?.cancel()
        self.countdownTimerSubscription = self.timerPublisher
            .sink { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stopCountdown(missed: true, taskWasActuallySelected: self.selectedTask)
                }
            }
    }

    private func stopCountdown(missed: Bool, taskWasActuallySelected: Task?) {
        print("Stopping countdown for task: \(taskWasActuallySelected?.title ?? "N/A"). Missed step: \(missed)")
        self.countdownTimerSubscription?.cancel()
        self.countdownTimerSubscription = nil
        self.countdownActive = false
        
        if self.showingImagePicker {
            self.showingImagePicker = false
        }

        if missed, let taskID = taskWasActuallySelected?.id, let index = taskStore.tasks.firstIndex(where: { $0.id == taskID }) {
            var taskToUpdate = taskStore.tasks[index]
            if taskToUpdate.completionStyle == .singleImage && !taskToUpdate.isCompleted {
                taskToUpdate.isMissed = true
                print("Task '\(taskToUpdate.title)' (single) marked as missed in store due to countdown.")
            } else if taskToUpdate.completionStyle == .twoPhoto {
                if currentImageCapturePurpose == .singleOrStart && taskToUpdate.startImageData == nil {
                    print("Task '\(taskToUpdate.title)' (two-photo): Start image upload window missed via countdown.")
                } else if currentImageCapturePurpose == .completion && taskToUpdate.completionImageData == nil {
                    print("Task '\(taskToUpdate.title)' (two-photo): Completion image upload window missed via countdown.")
                }
            }
            taskStore.tasks[index] = taskToUpdate
        }
    }
    
    private func handleImageSelection(newImage: UIImage?) {
        guard let image = newImage else {
            if self.countdownActive {
                 print("TaskView handleImageSelection: newImage is nil, countdown was active. Sheet's onDismiss or timer handles miss.")
            } else {
                 print("TaskView handleImageSelection: newImage is nil, no countdown active.")
                 self.selectedTask = nil
            }
            return
        }

        guard let taskToProcess = self.selectedTask else {
            print("TaskView handleImageSelection: No selected task to process image for.")
            self.selectedImage = nil
            return
        }

        if self.countdownActive {
            self.stopCountdown(missed: false, taskWasActuallySelected: taskToProcess)
        }

        let now = Date()
        var specificImageWasLate: Bool = false 
        
        guard let taskIndex = taskStore.tasks.firstIndex(where: { $0.id == taskToProcess.id }) else {
            print("TaskView handleImageSelection: Task \(taskToProcess.title) not found in store.")
            self.selectedImage = nil
            self.selectedTask = nil
            return
        }
        
        var taskToUpdate = taskStore.tasks[taskIndex]

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("TaskView handleImageSelection: Could not convert UIImage to Data.")
            self.selectedImage = nil
            self.selectedTask = nil
            return
        }

        if taskToUpdate.completionStyle == .singleImage || (taskToUpdate.completionStyle == .twoPhoto && self.currentImageCapturePurpose == .singleOrStart) {
            if taskToUpdate.startImageData != nil && taskToUpdate.completionStyle == .twoPhoto {
                 print("TaskView handleImageSelection: Overwriting start image for \(taskToUpdate.title).")
            }
            taskToUpdate.startImageData = imageData
            taskToUpdate.startImageTimestamp = now
            
            if taskToUpdate.completionStyle == .twoPhoto {
                if let startDate = taskToUpdate.startDate {
                    specificImageWasLate = now > startDate.addingTimeInterval(3600)
                    taskToUpdate.wasStartUploadLate = specificImageWasLate
                    print("TaskView: \(taskToUpdate.title) - Start image uploaded. Late: \(specificImageWasLate)")
                } else {
                    taskToUpdate.wasStartUploadLate = false
                    specificImageWasLate = false
                    print("TaskView: \(taskToUpdate.title) - Start image uploaded (no specific start date). Not considered late.")
                }
                taskToUpdate.isCompleted = false
                taskToUpdate.isMissed = false
            } else {
                specificImageWasLate = now > taskToUpdate.dueDate
                taskToUpdate.wasCompletionUploadLate = specificImageWasLate
                taskToUpdate.isCompleted = true
                taskToUpdate.isMissed = false
                print("TaskView: \(taskToUpdate.title) - Single image task completed. Late: \(specificImageWasLate)")
            }
            
            taskStore.tasks[taskIndex] = taskToUpdate
            feedStore.createOrUpdatePostForStartImage(task: taskToUpdate, image: image, timestamp: now, wasStartImageLate: taskToUpdate.wasStartUploadLate ?? specificImageWasLate)

        } else if taskToUpdate.completionStyle == .twoPhoto && self.currentImageCapturePurpose == .completion {
            if taskToUpdate.startImageData == nil {
                print("TaskView handleImageSelection: ERROR - Attempting to upload completion image for \(taskToUpdate.title) but start image is missing.")
                self.selectedImage = nil
                self.selectedTask = nil
                return
            }
            taskToUpdate.completionImageData = imageData
            taskToUpdate.completionImageTimestamp = now
            specificImageWasLate = now > taskToUpdate.dueDate
            taskToUpdate.wasCompletionUploadLate = specificImageWasLate
            print("TaskView: \(taskToUpdate.title) - Completion image uploaded. Late: \(specificImageWasLate)")
            
            taskToUpdate.isCompleted = true
            taskToUpdate.isMissed = false

            taskStore.tasks[taskIndex] = taskToUpdate
            feedStore.updatePostWithCompletionImage(taskID: taskToUpdate.id, image: image, timestamp: now, wasCompletionImageLate: specificImageWasLate)
        }
        
        taskStore.cancelNotification(for: taskToUpdate)
        taskStore.scheduleNotification(for: taskToUpdate)

        self.selectedImage = nil
        self.selectedTask = nil
    }
    
    private func checkForNotificationTask(isDirectPhotoFlow: Bool) {
        guard let taskID = navigationState.taskIDToOpen else { return }

        if let taskToOpen = taskStore.tasks.first(where: { $0.id == taskID && !($0.isCompleted || $0.isMissed) }) {
            selectedTask = taskToOpen
            
            var determinedPurpose: ImageCapturePurpose = .singleOrStart
            if taskToOpen.completionStyle == .twoPhoto {
                if taskToOpen.startImageData == nil {
                    determinedPurpose = .singleOrStart
                } else if taskToOpen.completionImageData == nil {
                    determinedPurpose = .completion
                } else {
                    print("TaskView checkForNotificationTask: Task \(taskToOpen.title) is two-photo with both images; flow trigger might be redundant.")
                }
            }
            self.currentImageCapturePurpose = determinedPurpose

            if isDirectPhotoFlow {
                print("TaskView checkForNotificationTask: Initiating direct photo flow for \(taskToOpen.title), determined purpose: \(self.currentImageCapturePurpose).")
                self.requestedImageSource = .photoLibrary
                startCountdown(for: taskToOpen)
            } else {
                print("TaskView checkForNotificationTask: Showing completion alert for \(taskToOpen.title).")
                showingCompletionAlert = true
            }
            navigationState.taskIDToOpen = nil
        } else {
            print("TaskView checkForNotificationTask: Task with ID \(taskID) not found, or already completed/missed.")
            navigationState.taskIDToOpen = nil
        }
    }
}

struct TaskBubbleView: View {
    let task: Task
    @Binding var selectedTask: Task?
    @Binding var showingCompletionAlert: Bool
    var onShowDetails: ((Task) -> Void)?

    @EnvironmentObject var calendarImporter: CalendarImporter
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme

    @State private var showingCalendarExportAlert = false
    @State private var calendarExportAlertTitle = ""
    @State private var calendarExportAlertMessage = ""
    @State private var showingInvalidLinkAlert = false

    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private var statusMessage: (text: String, color: Color)? {
        if task.isCompleted {
            return ("Completed", .green)
        }
        if task.isMissed {
            return ("Missed", .red)
        }
        switch task.completionStyle {
        case .singleImage:
            return ("Tap to complete with photo", .blue)
        case .twoPhoto:
            if task.startImageData == nil {
                return ("Tap to add start photo", .purple)
            } else if task.completionImageData == nil {
                return ("In Progress - Tap to add completion photo", .orange)
            }
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted || task.isMissed, color: .gray)
                    .foregroundColor(task.isCompleted || task.isMissed ? .gray : (colorScheme == .dark ? .white : .black))
                
                if let status = statusMessage {
                    Text(status.text)
                        .font(.caption)
                        .foregroundColor(status.color)
                        .padding(.top, 2)
                }

                Text("Due: \(task.dueDate, formatter: Self.timeFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if task.completionStyle == .twoPhoto, let startDate = task.startDate, task.startImageData == nil {
                     Text("Start: \(startDate, formatter: Self.timeFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            if !task.isCompleted && !task.isMissed {
                if task.completionStyle == .twoPhoto {
                    if task.startImageData == nil {
                        Image(systemName: "camera.badge.ellipsis")
                            .foregroundColor(.purple)
                    } else if task.completionImageData == nil {
                         Image(systemName: "camera.fill.badge.ellipsis")
                            .foregroundColor(.orange)
                    }
                } else {
                    Image(systemName: "camera")
                        .foregroundColor(.blue)
                }
            } else if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if task.isMissed {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }

        }
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemGray6))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture {
            print("TaskBubbleView .onTapGesture: Task '\(task.title)' tapped. Style: \(task.completionStyle), isCompleted: \(task.isCompleted), isMissed: \(task.isMissed)")
            if task.isCompleted || task.isMissed {
                if let showDetails = onShowDetails {
                    print("TaskBubbleView: Showing details for completed/missed task.")
                    showDetails(task)
                }
            } else {
                print("TaskBubbleView: Active task tapped. Setting selectedTask to '\(task.title)' and showing alert.")
                selectedTask = task
                showingCompletionAlert = true
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !task.isCompleted && !task.isMissed {
                Button {
                    exportToCalendar()
                } label: {
                    Label("Calendar", systemImage: "calendar.badge.plus")
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let showDetails = onShowDetails {
                Button {
                    showDetails(task)
                } label: {
                    Label("Details", systemImage: "info.circle.fill")
                }
                .tint(.accentColor)
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
