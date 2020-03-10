//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()

    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMesssages()
    }
    
    func loadMesssages() {
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { (querySnapshot, error) in
            self.messages = []

            if let e = error {
                print("Fetching Fail: \(e)")
            } else if let snapshots = querySnapshot?.documents {
                if (snapshots.count == 0) {
                    return
                }

                for doc in snapshots {
                    let data = doc.data()
                    
                    if let messageBody = data[K.FStore.bodyField] as? String, let messageSender = data[K.FStore.senderField] as? String{
                        let message = Message(body: messageBody, sender: messageSender)
                        self.messages.append(message)
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody = messageTextfield.text, let sender = Auth.auth().currentUser?.email {
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField: sender,
                K.FStore.bodyField: messageBody,
                K.FStore.dateField: Date().timeIntervalSince1970
            ]) { (error) in
                if let e = error {
                    print("Error from FireStore: \(e)")
                } else {
                    print("Success")
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                }
            }
        }
    }

    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        
        let currentLogedInUser = Auth.auth().currentUser

        if message.sender == currentLogedInUser?.email {
            cell.rightImageView.isHidden = false
            cell.leftImageView.isHidden = true
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
        } else {
            cell.rightImageView.isHidden = true
            cell.leftImageView.isHidden = false
            cell.label.textColor = UIColor(named: K.BrandColors.lighBlue)
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.blue)
        }

        return cell
    }
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle.rawValue == 1 {
//            messages.remove(at: indexPath.row)
//            tableView.deleteRows(at: [indexPath], with: .automatic)
//        }
//    }
}
