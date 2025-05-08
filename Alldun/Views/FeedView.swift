import SwiftUI

struct FeedView: View {
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var userStore: UserStore
    
    @State private var searchText = ""
    @State private var commentInputs: [UUID: String] = [:]

    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return []
        } else {
            return userStore.allUsers.filter { user in
                user.username.localizedCaseInsensitiveContains(searchText) ||
                user.fullName.localizedCaseInsensitiveContains(searchText)
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
                                UserRow(user: user)
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
                                let postAuthor = userStore.allUsers.first(where: { $0.id == post.userID })
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(postAuthor?.fullName ?? "Unknown User").bold()
                                    Image(uiImage: post.image)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(10)
                                    HStack {
                                        Text("Completed: \(post.task)")
                                        Spacer()
                                        Button(action: {
                                            feedStore.toggleLike(for: post.id)
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
                                        let commentBinding = Binding<String>(
                                            get: { self.commentInputs[post.id, default: ""] },
                                            set: { self.commentInputs[post.id] = $0 }
                                        )
                                        
                                        TextField("Add a comment...", text: commentBinding)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .font(.caption)
                                        
                                        Button(action: {
                                            guard let currentUserID = userStore.allUsers.first?.id else {
                                                print("FeedView: Cannot post comment. No current user ID found (using placeholder).")
                                                return
                                            }
                                            let commentText = commentInputs[post.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
                                            if !commentText.isEmpty {
                                                feedStore.addComment(to: post.id, by: currentUserID, text: commentText)
                                                commentInputs[post.id] = "" 
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            }
                                        }) {
                                            Text("Post")
                                                .font(.caption.bold())
                                        }
                                        .disabled(commentInputs[post.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(.vertical, 8)
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

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text(user.fullName).bold()
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: {
                print("Attempting to add friend: \(user.username)")
            }) {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}
