import SwiftUI
import EventKit

struct ProfileView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var calendarImporter = CalendarImporter()

    var userForProfile: User?
    
    @State private var showingCalendarAccessAlert = false
    @State private var currentCalendarError: CalendarImportError? = nil
    @State private var fetchedEvents: [EKEvent] = []
    @State private var showingEventSelectionSheet = false
    @State private var importMessage: String? = nil
    @State private var pushNotificationsEnabled: Bool = true // This might need to be per-user if settings are stored
    @State private var showingImagePickerForProfile = false
    @State private var newProfileUIImage: UIImage?

    @State private var isEditingBio: Bool = false
    @State private var editableBio: String = ""

    private var displayedUser: User? {
        userForProfile ?? userStore.currentUser
    }

    private var isViewingOwnProfile: Bool {
        guard let displayed = displayedUser, let current = userStore.currentUser else {
            return false // If either is nil, assume not own profile for safety
        }
        return displayed.id == current.id
    }

    var body: some View {
        let _ = print("ProfileView.body: Re-evaluating. showingEventSelectionSheet: \(showingEventSelectionSheet), fetchedEvents count: \(fetchedEvents.count)")
        NavigationView {
            List {
                // Section: User Information
                if let user = displayedUser {
                    Section {
                        VStack(alignment: .center, spacing: 15) {
                            Button(action: {
                                // This action is only for editing the profile picture
                                if isViewingOwnProfile {
                                    self.showingImagePickerForProfile = true
                                }
                            }) {
                                ZStack(alignment: .bottomTrailing) {
                                    Group {
                                        // Profile image logic...
                                        // If viewing own profile and newProfileUIImage exists, use it
                                        if isViewingOwnProfile, let selectedUiImage = newProfileUIImage {
                                            Image(uiImage: selectedUiImage)
                                                .resizable()
                                        } else if let imageName = user.profileImageName {
                                            Image(imageName)
                                                .resizable()
                                        } else {
                                            Image("default_avatar")
                                                .resizable()
                                        }
                                    }
                                    .scaledToFill()
                                    .frame(width: 100, height: 100) // This frames the image content
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))

                                    if isViewingOwnProfile {
                                        Image(systemName: "pencil.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.accentColor)
                                            .background(Circle().fill(Color(UIColor.systemBackground)))
                                            .offset(x: 5, y: 5) // Adjust offset as needed
                                            .allowsHitTesting(false) // So tap goes to the main button action
                                    }
                                }
                                .frame(width: 100, height: 100) // Ensure the ZStack (Button's label) has this frame
                            }
                            .buttonStyle(.plain) // Keeps default image appearance, doesn't add button chrome
                            .contentShape(Circle())
                            .frame(width: 100, height: 100)
                            .padding(.bottom, 5) // Padding outside the tappable area of the button


                            Text(user.fullName)
                                .font(.title2).bold()
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if isViewingOwnProfile && isEditingBio {
                                VStack {
                                    TextEditor(text: $editableBio)
                                        .frame(height: 100)
                                        .border(Color.gray.opacity(0.5), width: 1)
                                        .cornerRadius(5)
                                    HStack {
                                        Button("Cancel") {
                                            isEditingBio = false
                                        }
                                        .buttonStyle(.bordered)
                                        Spacer()
                                        Button("Save Bio") {
                                            // Make sure userStore.updateUserBio uses displayedUser.id
                                            userStore.updateUserBio(userID: user.id, newBio: editableBio)
                                            isEditingBio = false
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                                if let bio = user.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .onTapGesture {
                                            if isViewingOwnProfile {
                                                editableBio = user.bio ?? ""
                                                isEditingBio = true
                                            }
                                        }
                                } else {
                                    if isViewingOwnProfile {
                                        Button("(Tap to add bio)") {
                                            editableBio = ""
                                            isEditingBio = true
                                        }
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    } else {
                                        Text("(No bio provided)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            
                            if !user.friendIDs.isEmpty {
                                NavigationLink(destination: FriendsListView(user: user)) {
                                    HStack {
                                        Spacer()
                                        Text("\(user.friendIDs.count) Friend\(user.friendIDs.count == 1 ? "" : "s")")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                    }
                                }
                                .padding(.top, 5)
                            } else {
                                HStack {
                                    Spacer()
                                    Text("0 Friends")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.top, 5)
                            }

                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color(UIColor.systemGroupedBackground))
                } else {
                    Section {
                        Text("User profile not available.")
                    }
                }
                
                // Productivity Stats and Achievements can be shown for any user
                // (Assuming data source can provide this for any user)
                Section("Productivity Stats") {
                    Text("5-Day Task Completion Streak: --") // Placeholder, needs data for displayedUser
                    Text("Tasks Completed: --") // Placeholder, needs data for displayedUser
                    Text("Most Active: --") // Placeholder, needs data for displayedUser
                }

                Section("Achievements") {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("First Proof Uploaded")
                    }
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("7 Tasks in a Week")
                    }
                }

                if isViewingOwnProfile {
                    Section("Calendar Sync") {
                        Button("Import Events from Calendar") {
                            print("ProfileView: 'Import Events' button tapped at \(Date())")
                            importMessage = nil
                            currentCalendarError = nil
                            calendarImporter.requestAccess { granted, error in
                                print("ProfileView: requestAccess completion. Granted: \(granted), Error: \(String(describing: error)) at \(Date())")
                                if granted {
                                    print("CalendarImport: Access granted. Starting fetch at \(Date())")
                                    calendarImporter.fetchUpcomingEvents { result in
                                        print("CalendarImport: Fetch completed at \(Date())")
                                        DispatchQueue.main.async { // Ensure state updates are on main queue
                                            switch result {
                                            case .success(let eventsArray):
                                                print("CalendarImport: Fetched \(eventsArray.count) events.")
                                                self.fetchedEvents = eventsArray // Assign fetched events
                                                if eventsArray.isEmpty {
                                                    self.importMessage = "No upcoming events found."
                                                    self.showingCalendarAccessAlert = true // If you want an alert for "no events found"
                                                }
                                                self.showingEventSelectionSheet = true
                                                print("CalendarImport: EventSelectionSheet should now be shown. self.fetchedEvents count: \(self.fetchedEvents.count)")
                                                
                                            case .failure(let fetchError):
                                                self.currentCalendarError = fetchError
                                                self.fetchedEvents = [] // Clear events on failure
                                                self.showingCalendarAccessAlert = true // Show error alert
                                                print("CalendarImport: Fetch failed with error: \(fetchError) at \(Date())")
                                            }
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async { // Ensure state updates are on main queue
                                        self.currentCalendarError = error ?? .accessDenied
                                        self.fetchedEvents = [] // Clear events
                                        self.showingCalendarAccessAlert = true // Show error alert
                                        print("ProfileView: Calendar access denied or error occurred. Error: \(String(describing: self.currentCalendarError)) at \(Date())")
                                    }
                                }
                            }
                        }
                    }
                    
                    Section("Settings") {
                        NavigationLink("Privacy", destination: Text("Privacy Settings Screen (TODO)"))
                        Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                            .onChange(of: pushNotificationsEnabled) { _, newValue in
                                print("Push notifications toggled to: \(newValue)")
                                // TODO: This setting should ideally be saved per user if not global
                            }
                        // .disabled(currentUser == nil)
                        .disabled(!isViewingOwnProfile)
                        Picker("Appearance", selection: $themeManager.currentScheme) {
                            ForEach(AppearanceScheme.allCases) { scheme in
                                Text(scheme.rawValue).tag(scheme)
                            }
                        }
                        Button(action: {
                            userStore.logout()
                        }) {
                            Text("Log Out")
                                .foregroundColor(.red)
                        }
                        // .disabled(currentUser == nil)
                        .disabled(!isViewingOwnProfile) // Or perhaps just !userStore.isUserLoggedIn
                    }
                }

            }
            .listStyle(GroupedListStyle())
            .navigationTitle(isViewingOwnProfile ? "User Profile & Settings" : (displayedUser != nil ? "\(displayedUser!.username)'s Profile" : "Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .alert("Calendar Information", isPresented: $showingCalendarAccessAlert, presenting: currentCalendarError) { anErrorPresented in
                 Button("OK") { }
            } message: { anErrorPresented in
                if let msg = importMessage, self.currentCalendarError == nil { Text(msg) }
                else if let anError = self.currentCalendarError { Text(errorMessage(for: anError)) }
                else if let msg = importMessage { Text(msg) }
                else { Text("An unknown issue occurred.") }
            }
            .sheet(isPresented: $showingEventSelectionSheet, content: {
                let _ = print("ProfileView.sheet.content: Evaluating. showingEventSelectionSheet is \(showingEventSelectionSheet). fetchedEvents count: \(fetchedEvents.count)")
                
                EventSelectionView(events: fetchedEvents,
                                   taskStore: taskStore,
                                   importMessage: $importMessage,
                                   showingCalendarAccessAlert: $showingCalendarAccessAlert)
                    .environmentObject(userStore)
            })
            .sheet(isPresented: $showingImagePickerForProfile) {
                ImagePicker(selectedImage: self.$newProfileUIImage, sourceType: .photoLibrary)
            }
            .onAppear {
                print("ProfileView appeared. Displaying profile for: \(displayedUser?.username ?? "None"). Is own profile: \(isViewingOwnProfile)")
                if isViewingOwnProfile {
                    // Load editableBio from displayedUser if editing own profile
                    editableBio = displayedUser?.bio ?? ""
                    // Potentially load push notification status for the current user
                    // pushNotificationsEnabled = userStore.currentUser?.settings.pushNotificationsEnabled ?? true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Useful on iPad/macOS
    }

    private func errorMessage(for error: CalendarImportError) -> String {
        switch error {
        case .accessDenied:
            return "Calendar access was denied. Please enable it in Settings."
        case .accessRestricted:
            return "Calendar access is restricted on this device."
        case .fetchFailed(let underlyingError):
            return "Failed to fetch calendar events. \(underlyingError?.localizedDescription ?? "")"
        case .unknown:
            return "An unknown error occurred while accessing the calendar."
        }
    }

    private func statusToString(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorized: return "authorized (deprecated)"
        case .fullAccess: return "fullAccess (iOS 17+)"
        case .writeOnly: return "writeOnly (iOS 17+)"
        @unknown default: return "unknown status"
        }
    }
}

struct EventRowView: View {
    let event: EKEvent
    @Binding var selectedEventIDs: Set<String>

    private var eventID: String {
        event.eventIdentifier ?? ""
    }

    var body: some View {
        let _ = print("EventRowView: Displaying event '\(event.title ?? "N/A")' with ID '\(event.eventIdentifier ?? "NO ID")'")
        HStack {
            VStack(alignment: .leading) {
                Text(event.title ?? "No Title")
                    .font(.headline)
                if let startDate = event.startDate {
                    Text("Starts: \(startDate, format: .dateTime)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                if let endDate = event.endDate, event.startDate != event.endDate {
                    Text("Ends: \(endDate, format: .dateTime)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            if selectedEventIDs.contains(eventID) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !eventID.isEmpty {
                if selectedEventIDs.contains(eventID) {
                    selectedEventIDs.remove(eventID)
                } else {
                    selectedEventIDs.insert(eventID)
                }
            }
        }
    }
}

struct EventSelectionView: View {
    let events: [EKEvent]
    @ObservedObject var taskStore: TaskStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedEventIDs: Set<String> = []
    @Binding var importMessage: String?
    @Binding var showingCalendarAccessAlert: Bool

    var body: some View {
        let _ = print("EventSelectionView: FULL body evaluated. Received \(events.count) events. First event title: \(events.first?.title ?? "N/A (or list was empty)")")
        NavigationView {
            VStack {
                if events.isEmpty {
                    Text("No events found to import.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(events, id: \.eventIdentifier) { event in
                            EventRowView(event: event, selectedEventIDs: $selectedEventIDs)
                        }
                    }
                }
            }
            .navigationTitle("Select Events to Import")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import Selected") {
                        importSelectedEvents()
                        // dismiss() // Already in importSelectedEvents, but ensure it's consistent
                    }
                    .disabled(selectedEventIDs.isEmpty)
                }
            }
        }
        .onAppear { // Keep this for good measure
            print("EventSelectionView: .onAppear. Received \(events.count) events.")
        }
    }

    private func importSelectedEvents() {
        var importedCount = 0
        guard let currentUserID = userStore.currentUser?.id else {
            print("EventSelectionView importSelectedEvents: ERROR - Current user is not available.")
            self.importMessage = "Error: Could not assign tasks. Please ensure you are logged in and try again."
            self.showingCalendarAccessAlert = true
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let existingTaskIdentifiers: Set<String> = Set(taskStore.tasks.filter { $0.userID == currentUserID }.map { task in
            let title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let dayString = dateFormatter.string(from: task.dueDate)
            return "\(title)|\(dayString)|\(task.userID)"
        })

        var newTasksToAdd: [Task] = []

        for eventID in selectedEventIDs {
            if let event = events.first(where: { $0.eventIdentifier == eventID }) {
                let eventTitle = (event.title ?? "Untitled Event").trimmingCharacters(in: .whitespacesAndNewlines)
                let eventStartDate = event.startDate ?? Date()
                let eventDayString = dateFormatter.string(from: eventStartDate)
                let taskIdentifierForEvent = "\(eventTitle)|\(eventDayString)|\(currentUserID)"

                if !existingTaskIdentifiers.contains(taskIdentifierForEvent) {
                    let newTask = Task(
                        title: eventTitle,
                        dueDate: eventStartDate,
                        completionStyle: .singleImage,
                        isCompleted: false,
                        taskType: .miscellaneous,
                        priority: .medium,
                        userID: currentUserID
                    )
                    newTasksToAdd.append(newTask)
                    importedCount += 1
                } else {
                    print("Skipping duplicate event for current user: \(eventTitle)")
                }
            }
        }
        
        if !newTasksToAdd.isEmpty {
            print("EventSelectionView: Attempting to add \(newTasksToAdd.count) new tasks to TaskStore.")
            for task in newTasksToAdd {
                print("EventSelectionView: Adding task - Title: '\(task.title)', Due: \(task.dueDate), UserID: \(task.userID), TaskID: \(task.id)")
            }
            taskStore.tasks.append(contentsOf: newTasksToAdd)
            for task in newTasksToAdd {
                taskStore.scheduleNotification(for: task)
            }
        }

        if importedCount > 0 {
            importMessage = "Successfully imported \(importedCount) event(s) as tasks."
        } else if !selectedEventIDs.isEmpty && importedCount == 0 {
             importMessage = "Selected event(s) already exist as tasks for you or could not be imported."
        } else {
            importMessage = "No new events were imported."
        }
        showingCalendarAccessAlert = true
        dismiss()
    }
}
