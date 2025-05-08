import SwiftUI
import Combine
import UserNotifications

@main
struct AldunApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var taskStore = TaskStore()
    @StateObject private var feedStore = FeedStore()
    @StateObject private var navigationState = AppNavigationState()
    @StateObject private var userStore = UserStore()
    @StateObject private var calendarImporter = CalendarImporter()
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        print("AldunApp init: TaskStore created. Initial tasks count: \(taskStore.tasks.count)")
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(taskStore)
                .environmentObject(feedStore)
                .environmentObject(navigationState)
                .environmentObject(userStore)
                .environmentObject(calendarImporter)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentScheme.toColorScheme())
                .onReceive(NotificationCenter.default.publisher(for: .didRequestTaskOpen)) { notification in
                    if let taskID = notification.userInfo?["taskID"] as? UUID {
                        print("AldunApp: Received notification to open taskID: \(taskID)")
                        DispatchQueue.main.async {
                            self.navigationState.taskIDToOpen = taskID
                        }
                    }
                }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission denied.")
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var calendarImporter: CalendarImporter
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var navigationState: AppNavigationState
    @EnvironmentObject var userStore: UserStore

    var body: some View {
        TabView {
            TaskView(calendarImporter: self.calendarImporter)
                .tabItem { Label("Home", systemImage: "house.fill") }
            
            FeedView()
                .tabItem { Label("Feed", systemImage: "list.bullet.rectangle.fill") }

            // REMOVE: AddTaskView from TabView
            // AddTaskView()
            //     .tabItem { Label("Add", systemImage: "plus.circle.fill") }

            LeaderboardView()
                .tabItem { Label("Leaderboard", systemImage: "star.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        // REMOVE: .accentColor(.black) to allow system default adaptive accent color
        // .accentColor(.black)
    }
}
