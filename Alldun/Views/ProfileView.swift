import SwiftUI
import EventKit

struct ProfileView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var calendarImporter = CalendarImporter()
    
    @State private var showingCalendarAccessAlert = false
    @State private var currentCalendarError: CalendarImportError? = nil
    @State private var fetchedEvents: [EKEvent]? = nil
    @State private var showingEventSelectionSheet = false
    @State private var importMessage: String? = nil
    @State private var pushNotificationsEnabled: Bool = true
    @State private var showingImagePickerForProfile = false
    @State private var newProfileUIImage: UIImage?

    @State private var isEditingBio: Bool = false
    @State private var editableBio: String = ""

    private var currentUser: User? {
        userStore.currentUser
    }

    var body: some View {
        NavigationView {
            List {
                // Section: User Information
                if let user = currentUser {
                    Section {
                        VStack(spacing: 15) {
                            HStack {
                                Spacer()
                                Group {
                                    if let selectedUiImage = newProfileUIImage {
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
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                Spacer()
                                Button("Edit") {
                                    self.showingImagePickerForProfile = true
                                }
                                .padding(.leading, -40)
                                .padding(.top, -30)
                            }


                            Text(user.fullName)
                                .font(.title2).bold()
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if isEditingBio {
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
                                            editableBio = user.bio ?? ""
                                            isEditingBio = true
                                        }
                                } else {
                                    Button("(Tap to add bio)") {
                                        editableBio = ""
                                        isEditingBio = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color(UIColor.systemGroupedBackground))
                } else {
                    Section {
                        Text("No user data found.")
                    }
                }
                
                Section("Productivity Stats") {
                    Text("5-Day Task Completion Streak: --")
                    Text("Tasks Completed: --")
                    Text("Most Active: --")
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

                Section("Calendar Sync") {
                    Button("Import Events from Calendar") {
                        importMessage = nil
                        currentCalendarError = nil
                        calendarImporter.requestAccess { granted, error in
                            if granted {
                                calendarImporter.fetchUpcomingEvents { result in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success(let events):
                                            if events.isEmpty {
                                                self.importMessage = "No upcoming events found."
                                                self.showingCalendarAccessAlert = true
                                            } else {
                                                self.fetchedEvents = events
                                                self.showingEventSelectionSheet = true
                                            }
                                        case .failure(let fetchError):
                                            self.currentCalendarError = fetchError
                                            self.showingCalendarAccessAlert = true
                                        }
                                    }
                                }
                            } else {
                                self.currentCalendarError = error ?? .accessDenied
                                self.showingCalendarAccessAlert = true
                            }
                        }
                    }
                }
                
                Section("Settings") {
                    NavigationLink("Privacy", destination: Text("Privacy Settings Screen (TODO)"))
                    Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                        .onChange(of: pushNotificationsEnabled) { _, newValue in
                            print("Push notifications toggled to: \(newValue)")
                        }
                    Picker("Appearance", selection: $themeManager.currentScheme) {
                        ForEach(AppearanceScheme.allCases) { scheme in
                            Text(scheme.rawValue).tag(scheme)
                        }
                    }
                    // Add more settings later
                }

            }
            .listStyle(GroupedListStyle())
            .navigationTitle("User Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Calendar Information", isPresented: $showingCalendarAccessAlert, presenting: self.currentCalendarError) { anErrorPresented in
                 Button("OK") { }
            } message: { anErrorPresented in
                if let msg = importMessage, self.currentCalendarError == nil { Text(msg) }
                else if let anError = self.currentCalendarError { Text(errorMessage(for: anError)) }
                else if let msg = importMessage { Text(msg) }
                else { Text("An unknown issue occurred.") }
            }
            .sheet(isPresented: $showingEventSelectionSheet, content: {
                if let events = fetchedEvents {
                    EventSelectionView(events: events, taskStore: taskStore, importMessage: $importMessage, showingCalendarAccessAlert: $showingCalendarAccessAlert)
                        .environmentObject(userStore)
                } else { Text("No events to display.") }
            })
            .sheet(isPresented: $showingImagePickerForProfile) {
                ImagePicker(selectedImage: self.$newProfileUIImage, sourceType: .photoLibrary)
            }
            .onAppear {
                print("ProfileView appeared. Current user: \(currentUser?.username ?? "None")")
            }
        }
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
                        dismiss()
                    }
                    .disabled(selectedEventIDs.isEmpty)
                }
            }
        }
    }

    private func importSelectedEvents() {
        var importedCount = 0
        guard let placeholderUserID = userStore.allUsers.first?.id else {
            print("EventSelectionView importSelectedEvents: ERROR - No users available in UserStore to assign to Task.")
            self.importMessage = "Error: Could not assign tasks to a user. Please try again."
            self.showingCalendarAccessAlert = true
            return
        }

        for eventID in selectedEventIDs {
            if let event = events.first(where: { $0.eventIdentifier == eventID }) {
                let existingTask = taskStore.tasks.first { $0.title == (event.title ?? "Untitled Event") && Calendar.current.isDate($0.dueDate, inSameDayAs: event.startDate) }

                if existingTask == nil {
                    let newTask = Task(
                        title: event.title ?? "Untitled Event",
                        dueDate: event.startDate ?? Date(),
                        isCompleted: false,
                        userID: placeholderUserID
                    )
                    taskStore.tasks.append(newTask)
                    taskStore.scheduleNotification(for: newTask)
                    importedCount += 1
                } else {
                    print("Skipping duplicate event: \(event.title ?? "Untitled Event")")
                }
            }
        }
        if importedCount > 0 {
            importMessage = "Successfully imported \(importedCount) event(s) as tasks."
        } else if !selectedEventIDs.isEmpty && importedCount == 0 {
             importMessage = "Selected event(s) already exist as tasks or could not be imported."
        } else {
            importMessage = "No new events were imported."
        }
        showingCalendarAccessAlert = true
    }
}
