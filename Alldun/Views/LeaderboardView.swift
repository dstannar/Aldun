import SwiftUI

struct LeaderboardEntry: Identifiable {
    let id: User.ID
    let username: String
    let fullName: String
    let completedTasksCount: Int
}

struct LeaderboardView: View {
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var taskStore: TaskStore

    private var leaderboardData: [LeaderboardEntry] {
        let completedTasks = taskStore.tasks.filter { $0.isCompleted }

        let taskCountsByUserID = Dictionary(grouping: completedTasks, by: { $0.userID })
            .mapValues { $0.count }

        let entries = userStore.allUsers.map { user -> LeaderboardEntry in
            LeaderboardEntry(
                id: user.id,
                username: user.username,
                fullName: user.fullName,
                completedTasksCount: taskCountsByUserID[user.id] ?? 0
            )
        }

        return entries.sorted { $0.completedTasksCount > $1.completedTasksCount }
    }

    var body: some View {
        NavigationView {
            List {
                if leaderboardData.isEmpty {
                    Text("No tasks completed yet. Complete some tasks to appear on the leaderboard!")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(leaderboardData.indices, id: \.self) { index in
                        let entry = leaderboardData[index]
                        HStack {
                            Text("\(index + 1).") // Rank
                            VStack(alignment: .leading) {
                                Text(entry.fullName)
                                    .font(.headline)
                                Text("@\(entry.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("\(entry.completedTasksCount) tasks")
                                .font(.title3)
                        }
                    }
                }
            }
            .navigationTitle("Leaderboard")
        }
    }
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        let taskStore = TaskStore()
        
        if let firstUser = userStore.allUsers.first, 
           let secondUser = userStore.allUsers.dropFirst().first,
           let thirdUser = userStore.allUsers.dropFirst(2).first {
            taskStore.tasks = [
                Task(title: "Run 5k", dueDate: Date(), isCompleted: true, taskType: .exercise, userID: firstUser.id),
                Task(title: "Read Chapter 1", dueDate: Date(), isCompleted: true, taskType: .study, userID: firstUser.id),
                Task(title: "Yoga Session", dueDate: Date(), isCompleted: false, taskType: .exercise, userID: firstUser.id), 

                Task(title: "Math Homework", dueDate: Date(), isCompleted: true, taskType: .homework, userID: secondUser.id),
                Task(title: "Project Proposal", dueDate: Date(), isCompleted: false, taskType: .homework, userID: secondUser.id), 

                Task(title: "Clean Garage", dueDate: Date(), isCompleted: true, taskType: .miscellaneous, userID: thirdUser.id),
                Task(title: "Buy Groceries", dueDate: Date(), isCompleted: true, taskType: .miscellaneous, userID: thirdUser.id),
                Task(title: "Plan Weekend", dueDate: Date(), isCompleted: true, taskType: .miscellaneous, userID: thirdUser.id)
            ]
        }
        
        return LeaderboardView()
            .environmentObject(userStore)
            .environmentObject(taskStore) 
    }
}
