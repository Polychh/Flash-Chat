//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()//reference database
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        
        title = K.appName
        navigationItem.hidesBackButton = true // hide back button
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier) // register custom MessageCell
        
        loadMessages()
    }
    
    func loadMessages(){ // read date from firebase firestore
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { (querySnapshot, error) in // it trigger every time when add new message, listen for realtime updates addSnapshotListener, order by dateField
            self.messages = [] // to delete duplecates of old messages every time when we get new one and add only new one
            if let e = error{
                print("There was an issue retrieving data from firestore \(e)")
            }else{
                if let snapshotDocuments = querySnapshot?.documents{
                    for doc in snapshotDocuments{
                        let data = (doc.data())
                        if let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField ] as? String{ // divede data into sender value and body value
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()// to send data to reusable cell and trigger UITableViewDataSource again
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)// choose the last element of array
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)// to scroll the messages automaticly to the last one
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) { // fill database firestore consist of messageSender, messageBody, Date (cuurent time when the message is created)
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email{
            db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.senderField: messageSender, K.FStore.bodyField: messageBody, K.FStore.dateField: Date().timeIntervalSince1970]) { (error) in
                if let e = error{
                    print("There was an issue saving data to firestore, \(e)")
                }else{
                    print("Seccessfully save data.")
                    DispatchQueue.main.async { // because we are in clousure and want to update user interface, because code in clousure take place on background thread and we want in main thread
                        self.messageTextfield.text = "" // clean textfield after sending a message
                    }
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true) // back to welcom screen
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

extension ChatViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // how many cells want in tableView
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // this method is going to get called for as many rows as have in tableView
        let message = messages[indexPath.row] // indexPath.row it is index of every row in array
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell // to cast reusable cell as a MessageCell class
        cell.label.text = message.body // indexPath.row it is a row number that indexing array meessage by sender, we can use label because cell as! MessageCell
        
        //This is a message from current user
        if  message.sender == Auth.auth().currentUser?.email{
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }
        // This is a message from another sender
        else{
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        return cell
    }
}


