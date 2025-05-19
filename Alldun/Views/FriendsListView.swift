import SwiftUI

struct FriendsListView: View {
    @EnvironmentObject var userStore: UserStore
    // We might need taskStore and themeManager if ProfileView, our destination, requires them
    // and they aren't consistently propagated. Let's add them just in case for now.
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var themeManager: ThemeManager

    let user: User // The user whose friends are being displayed

    private var friends: [User] {
        // Filter allUsers to find those whose IDs are in the user's friendIDs list
        userStore.allUsers.filter { friendUser in
            user.friendIDs.contains(friendUser.id)
        }
    }

    var body: some View {
        List {
            if friends.isEmpty {
                Text("\(user.username) has no friends yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(friends) { friend in
                    NavigationLink(destination: ProfileView(userForProfile: friend)
                        // Environment objects should propagate, but if not, pass them explicitly:
                        // .environmentObject(userStore)
                        // .environmentObject(taskStore)
                        // .environmentObject(themeManager)
                    ) {
                        // We can reuse UserRow or create a simpler version here
                        UserRowSimple(user: friend)
                    }
                }
            }
        }
        .navigationTitle("\(user.username)'s Friends")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// A simpler version of UserRow, or you can reuse the existing UserRow if suitable.
// If UserRow has action buttons like "Add Friend", those won't be appropriate here.
struct UserRowSimple: View {
    let user: User

    var body: some View {
        HStack {
            // Basic user display
            Image(user.profileImageName ?? "person.circle.fill") // Use a default system image or your asset
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .foregroundColor(user.profileImageName == nil ? .gray : .clear) // Show gray if no image

            VStack(alignment: .leading) {
                Text(user.fullName).bold()
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            // No action buttons needed here, just display
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct FriendsListView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock data for previewing
        
        let sampleUser = User(id: UUID(), username: "sampleUser", fullName: "Sample User", bio: "A sample bio.", profileImageName: nil, friendIDs: [UUID(), UUID()])
        
        let friend1 = User(id: sampleUser.friendIDs[0], username: "friendOne", fullName: "Friend One")
        let friend2 = User(id: sampleUser.friendIDs[1], username: "friendTwo", fullName: "Friend Two")

        let mockUserStore = UserStore()
        
        // ENSURE THIS IS 'let': 'previewUsers' is not mutated and should be a constant.
        let previewUsers = [sampleUser, friend1, friend2]
        mockUserStore.allUsers = previewUsers
        
        mockUserStore.currentUser = sampleUser

        let mockTaskStore = TaskStore()
        let mockThemeManager = ThemeManager()

        return NavigationView {
            FriendsListView(user: sampleUser)
                .environmentObject(mockUserStore)
                .environmentObject(mockTaskStore)
                .environmentObject(mockThemeManager)
        }
    }
}
#endif
