//
//  ListViewController.swift
//  LearnFirebase
//
//  Created by John Gallaugher on 4/15/17.
//  Copyright © 2017 Gallaugher. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class ListViewController: UIViewController {
    
    var listItemArray = [ListItem]()
    var itemsRef: FIRDatabaseReference!
    var userEmail = ""
    
    @IBOutlet weak var addButtonItem: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        itemsRef = FIRDatabase.database().reference(withPath: "items")
        
        itemsRef.observe(.value, with: { snapshot in
            self.listItemArray = []
            for child in snapshot.children {
                let itemSnapshot = child as! FIRDataSnapshot
                let newListItem = ListItem()
                let itemValue = itemSnapshot.value as! [String: AnyObject]
                newListItem.listItem = itemValue["listItem"] as! String
                newListItem.postedBy = itemValue["postedBy"] as! String
                newListItem.listItemKey = itemSnapshot.key
                print("The newListItem is: \(newListItem)")
                self.listItemArray.append(newListItem)
            }
            self.tableView.reloadData()
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print(">>> ListViewController has appeared!!!")
        
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            print("**** SignedIn indicated in ListViewController!")
            let userEmail = (FIRAuth.auth()?.currentUser?.email)!
            let displayName = FIRAuth.auth()?.currentUser?.displayName
            print("UUUU userEmail = \(userEmail), displayName = \(displayName)")
        } else {
            performSegue(withIdentifier: "ToLogin", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "ToEditItem":
            let destination = segue.destination as! DetailViewController
            let indexPath = tableView.indexPathForSelectedRow!
            destination.listItem = listItemArray[indexPath.row].listItem
        case "ToAddItem":
            if let selectedRow = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedRow, animated: true)
            }
        case "ToLogin" :
            print(">>> Performing segue ToLogin")
        default:
            print("*** Unexpected Segue in ListViewController.swift")
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        GIDSignIn.sharedInstance().signOut()
        performSegue(withIdentifier: "ToLogin", sender: nil)
    }
    
    @IBAction func unwindFromDetail(sender: UIStoryboardSegue) {
        
        if let userEmail = FIRAuth.auth()?.currentUser?.email {
            self.userEmail = userEmail
        } else {
            self.userEmail = ""
        }
        
        if let source = sender.source as? DetailViewController, let newItem = source.listItem {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                let index = selectedIndexPath.row
                listItemArray[index].listItem = newItem
                listItemArray[index].postedBy = userEmail
                let listItemKey = listItemArray[index].listItemKey
                self.itemsRef.child(listItemKey).setValue(["listItem": newItem, "postedBy": userEmail, "listItemKey": listItemKey])
            } else {
                
                let newListItem = ListItem()
                newListItem.listItem = newItem
                newListItem.postedBy = userEmail
                listItemArray.append(newListItem)
                let itemID = self.itemsRef.childByAutoId()
                itemID.setValue(["listItem": newListItem.listItem, "postedBy": newListItem.postedBy])
            }
            tableView.reloadData()
        } else {
            print("Error: Didn't come from DetailViewController or couldn't get listItem")
        }
    }
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItemArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = listItemArray[indexPath.row].listItem
        cell.detailTextLabel?.text = listItemArray[indexPath.row].postedBy
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let listItemKey = listItemArray[indexPath.row].listItemKey
            self.itemsRef.child(listItemKey).removeValue()
        }
    }
    
}
