//
//  UserListViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 31/12/25.
//

import UIKit

// MARK: - User List View Controller
class UserListViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var userListTableView: UITableView!
    private var users: [User] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadUsers()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Messages"
        view.backgroundColor = .systemBackground
    }
    
    private func setupTableView() {
        userListTableView.delegate = self
        userListTableView.dataSource = self
        userListTableView.rowHeight = 80
        userListTableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: "UserListCell")
    }
    
    private func loadUsers() {
        // Sample users
        users = [
            User(id: "1", name: "John Doe", lastMessage: "Hey! How are you?", lastMessageTime: Date().addingTimeInterval(-300), unreadCount: 2),
            User(id: "2", name: "Jane Smith", lastMessage: "Thanks for the help!", lastMessageTime: Date().addingTimeInterval(-3600), unreadCount: 0),
            User(id: "3", name: "Mike Johnson", lastMessage: "See you tomorrow!", lastMessageTime: Date().addingTimeInterval(-7200), unreadCount: 1),
            User(id: "4", name: "Sarah Williams", lastMessage: "That sounds great!", lastMessageTime: Date().addingTimeInterval(-86400), unreadCount: 0),
            User(id: "5", name: "Tom Brown", lastMessage: "Let me know when you're free", lastMessageTime: Date().addingTimeInterval(-172800), unreadCount: 5)
        ]
        userListTableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension UserListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserListCell", for: indexPath) as! UserListCell
        let user = users[indexPath.row]
        cell.configure(with: user)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension UserListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedUser = users[indexPath.row]
        let chatVC = storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        chatVC.user = selectedUser
        navigationController?.pushViewController(chatVC, animated: true)
    }
}


