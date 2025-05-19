import SwiftUI

struct FeedView: View {
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var taskStore: TaskStore
    
    @State private var searchText = ""
    
    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return []
        } else {
            return userStore.allUsers.filter { user in
                (user.username.localizedCaseInsensitiveContains(searchText) ||
                 user.fullName.localizedCaseInsensitiveContains(searchText))
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top)

                if !searchText.isEmpty {
                    if filteredUsers.isEmpty {
                        Text("No users found matching \"\(searchText)\".")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(filteredUsers) { user in
                                NavigationLink(destination: ProfileView(userForProfile: user)) {
                                    UserRow(user: user)
                                }
                            }
                        }
                    }
                } else {
                    if feedStore.posts.isEmpty {
                        Text("No feed items yet. Complete tasks to see them here.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(feedStore.posts) { post in
                                FeedPostRowView(post: post)
                            }
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("Feed & Users")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search users...", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
        }
    }
}

struct UserRow: View {
    let user: User
    @EnvironmentObject var userStore: UserStore
    
    private var friendshipStatus: FriendshipStatus {
        guard let currentUser = userStore.currentUser else { return .notFriends }
        if currentUser.id == user.id { return .isSelf }
        if userStore.areFriends(user1ID: currentUser.id, user2ID: user.id) {
            return .friends
        }
        return .notFriends
    }

    enum FriendshipStatus {
        case isSelf, friends, pendingSent, pendingReceived, notFriends
    }

    var body: some View {
        HStack {
            Image(user.profileImageName ?? "person.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .foregroundColor(user.profileImageName == nil ? .gray : .clear)
            
            VStack(alignment: .leading) {
                Text(user.fullName).bold()
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()

            switch friendshipStatus {
            case .isSelf:
                EmptyView()
            case .friends:
                Button(action: {
                    guard let currentUser = userStore.currentUser else {
                        print("UserRow: Cannot unfriend, no current user.")
                        return
                    }
                    print("UserRow: Attempting to unfriend user: \(user.username) by \(currentUser.username)")
                    userStore.removeFriend(currentUserInitiatorID: currentUser.id, friendToRemoveID: user.id)
                }) {
                    Image(systemName: "person.fill.badge.minus")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            case .pendingSent:
                Text("Requested")
                    .font(.caption)
                    .foregroundColor(.orange)
            case .pendingReceived:
                Button("Accept") { /* TODO: Accept request */ }
                    .font(.caption)
                    .buttonStyle(.plain)
            case .notFriends:
                Button(action: {
                    guard let currentUser = userStore.currentUser else {
                        print("UserRow: Cannot add friend, no current user.")
                        return
                    }
                    print("UserRow: Attempting to add friend: \(user.username) by \(currentUser.username)")
                    userStore.addFriend(currentUserInitiatorID: currentUser.id, friendToAddID: user.id)
                }) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FeedPostRowView: View {
    let post: FeedPost
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var feedStore: FeedStore
    
    @State private var commentInput: String = ""

    private var postAuthor: User? {
        userStore.allUsers.first(where: { $0.id == post.userID })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(postAuthor?.fullName ?? "Unknown User").bold()
                Spacer()
                if post.isOverallLate {
                    Text("LATE")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            
            if let startImg = post.startImage {
                Image(uiImage: startImg)
                    .resizable()
                    .scaledToFit()
            }
            if let completionImg = post.completionImage {
                 Image(uiImage: completionImg)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .padding(.top, 4)
            }
            
            HStack {
                Text("Completed: \(post.taskTitle)")
                Spacer()
                Button(action: {
                    feedStore.toggleLike(for: post.taskID)
                }) {
                    Image(systemName: post.liked ? "heart.fill" : "heart")
                        .foregroundColor(post.liked ? .red : .gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if !post.comments.isEmpty {
                    Text("Comments:")
                        .font(.caption.weight(.semibold))
                        .padding(.top, 4)
                    ForEach(post.comments) { comment in
                        HStack(alignment: .top) {
                            let commenter = userStore.allUsers.first(where: { $0.id == comment.userID })
                            Text("\(commenter?.username ?? "user"):").bold()
                            Text(comment.text)
                        }
                        .font(.caption)
                        .padding(.leading, 8)
                    }
                }
            }
            
            HStack {
                TextField("Add a comment...", text: $commentInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
                
                Button(action: {
                    guard let currentUserID = userStore.currentUser?.id else {
                        print("FeedPostRowView: Cannot post comment. No current user ID found.")
                        return
                    }
                    let commentText = commentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !commentText.isEmpty {
                        feedStore.addComment(to: post.taskID, by: currentUserID, text: commentText)
                        commentInput = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }) {
                    Text("Post")
                        .font(.caption.bold())
                }
                .disabled(commentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}
