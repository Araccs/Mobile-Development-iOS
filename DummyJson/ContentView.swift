import SwiftUI
import Alamofire

struct ContentView: View {
    @State private var text: String = ""
    @State private var selectedUser: User? // New state property
    @StateObject private var userViewModel = UserViewModel()

    var body: some View {
        VStack {
            // Button to fetch all users
            Button(action: {
                userViewModel.findAllUsers()
            }) {
                Text("Find All")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            // Text field for entering search text
            TextField("Enter text", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Button to search users by text
            Button(action: {
                userViewModel.findBySearch(text: text)
            }) {
                Text("Find by Search")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            // List to display users
            List(userViewModel.users) { user in
                VStack(alignment: .leading, spacing: 5) {
                    // User name
                    HStack {
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.headline)

                        Spacer()

                        // Button to delete user
                        Button(action: { userViewModel.deleteUser(user: user) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to prevent row selection

                        // Button to edit user
                        Button(action: {
                            selectedUser = user // Set the selected user
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to prevent row selection
                    }

                    // User age
                    Text("Age: \(user.age)")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    // User email
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Button to add a new user
            Button(action: {
                selectedUser = User(id: -1, firstName: "", lastName: "", email: "", age: 0) // Set a dummy user to represent a new user
            }) {
                Text("Add User")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .sheet(item: $selectedUser) { user in // Show user edit view when selectedUser is not nil
            UserEditView(user: user, userViewModel: userViewModel)
        }
    }
}

struct UsersResponse: Codable {
    let users: [User]
}

struct User: Codable, Identifiable {
    let id: Int
    var firstName: String
    var lastName: String
    let email: String
    let age: Int
}

class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    
    // Fetch all users from the API
    func findAllUsers() {
        AF.request("https://dummyjson.com/users").responseDecodable(of: UsersResponse.self) { response in
            switch response.result {
            case .success(let usersResponse):
                DispatchQueue.main.async {
                    self.users = usersResponse.users
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    // Search users by text
    func findBySearch(text: String) {
        AF.request("https://dummyjson.com/users/search?q=\(text)").responseDecodable(of: UsersResponse.self) { response in
            switch response.result {
            case .success(let usersResponse):
                DispatchQueue.main.async {
                    self.users = usersResponse.users
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    // Delete a user
    func deleteUser(user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users.remove(at: index)
        }
    }
    
    // Add a user
    func addUser(user: User) {
        users.append(user)
    }
    
    // Edit a user
    func editUser(user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        }
    }
}

struct UserEditView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var editedUserFirstName: String
    @State private var editedUserLastName: String
    @State private var editedUserEmail: String
    @State private var editedUserAge: String
    
    let user: User
    let userViewModel: UserViewModel
    
    init(user: User, userViewModel: UserViewModel) {
        self.user = user
        self.userViewModel = userViewModel
        _editedUserFirstName = State(initialValue: user.firstName)
        _editedUserLastName = State(initialValue: user.lastName)
        _editedUserEmail = State(initialValue: user.email)
        _editedUserAge = State(initialValue: "\(user.age)")
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Text fields for editing user details
                TextField("First Name", text: $editedUserFirstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Last Name", text: $editedUserLastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $editedUserEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Age", text: $editedUserAge)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .navigationBarTitle(Text(user.id == -1 ? "Add User" : "Edit User"), displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    // Create a new User object with the edited details
                    let editedUser = User(
                        id: user.id,
                        firstName: editedUserFirstName,
                        lastName: editedUserLastName,
                        email: editedUserEmail,
                        age: Int(editedUserAge) ?? 0
                    )
                    
                    // Check if it's a new user or an existing user and perform the appropriate action
                    if user.id == -1 {
                        userViewModel.addUser(user: editedUser)
                    } else {
                        userViewModel.editUser(user: editedUser)
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
