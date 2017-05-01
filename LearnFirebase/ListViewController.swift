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
    var rootRef: FIRDatabaseReference!
    var itemsRef: FIRDatabaseReference!
    var reviewsRef: FIRDatabaseReference!
    var userEmail = ""
    
    @IBOutlet weak var addButtonItem: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        rootRef = FIRDatabase.database().reference()
        itemsRef = FIRDatabase.database().reference(withPath: "items")
        reviewsRef = FIRDatabase.database().reference(withPath: "reviews")
        
        itemsRef.observe(.value, with: { snapshot in
            self.listItemArray = []
            for child in snapshot.children {
                let itemSnapshot = child as! FIRDataSnapshot
                let newListItem = ListItem()
                let itemValue = itemSnapshot.value as! [String: AnyObject]
                newListItem.placeName = (itemValue["placeName"] as? String ?? "")
                newListItem.postedBy = (itemValue["postedBy"] as? String ?? "")
                newListItem.listItemKey = itemSnapshot.key
                newListItem.latitude = (itemValue["latitude"] as? Double ?? 0.0)
                newListItem.longitude = (itemValue["longitude"] as? Double ?? 0.0)
                newListItem.address = (itemValue["address"] as? String ?? "")
                self.listItemArray.append(newListItem)
            }
            self.tableView.reloadData()
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print(">>> ListViewController has appeared!!!")
        
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            let userEmail = (FIRAuth.auth()?.currentUser?.email)!
            let displayName = FIRAuth.auth()?.currentUser?.displayName
        } else {
            performSegue(withIdentifier: "ToLogin", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "ToEditItem":
            let destination = segue.destination as! DetailViewController
            let indexPath = tableView.indexPathForSelectedRow!
            destination.listItem = listItemArray[indexPath.row]
        case "ToAddItem":
            let newLocationRef = self.itemsRef.childByAutoId()
            let newLocationRefKey = newLocationRef.key
            
            let destinationNavigationController = segue.destination as! UINavigationController
            let destination = destinationNavigationController.topViewController as! DetailViewController
            // Assign a new location key so this can be used for file names if photos are added.
            destination.newLocationRefKey = newLocationRefKey
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
                // then you must have edited a record by clicking on it
                let index = selectedIndexPath.row
                listItemArray[index] = newItem
                listItemArray[index].postedBy = userEmail
                let listItemKey = listItemArray[index].listItemKey
                
                // Generate a new push ID for the new location (stored in "items")
                let newLocationRef = rootRef.child("items").child(newItem.listItemKey)
                let newLocationKey = newLocationRef.key

                // Create a dictionary of all photo names associated with this location
                var photoDictionary = [String : Any]()
                for fileName in source.locationPhotoFileNames {
                    photoDictionary[fileName] = userEmail
                }
                
                // Create a dictionary of all reviews at this location
                var reviewDictionary = [String : Any]()
                
                for review in (source.listItem?.reviews)! {
                    var ratingsEntry = [String: Any]()
                    ratingsEntry["reviewHeadline"] = review.reviewHeadline
                    ratingsEntry["reviewText"] = review.reviewText
                    ratingsEntry["rating"] = review.rating
                    
                    let newReviewIndexRef = self.reviewsRef.child(newLocationKey).childByAutoId()
                    let newReviewRefKey = newReviewIndexRef.key
                    reviewDictionary["\(newReviewRefKey)"] = ratingsEntry
                }

                /*
        - reviewIndex
            - unique item key (locationKey)
                 - uniqueReviewKey
                        - reviewHeadline
                        - reviewText
                        - userName
                        - rating
                        - reviewBy
                 - anotherUniqueReviewKey
                    - reviewHeadline
                    - reviewText
                    - userName
                    - rating
                    - reviewBy
                */
                
                // Create the data we want to update
                
                let updatedUserData = ["items/\(newLocationKey)": ["placeName": newItem.placeName, "postedBy": userEmail, "listItemKey": listItemKey, "latitude": newItem.latitude, "longitude": newItem.longitude, "address": newItem.address], "reviews/\(newLocationKey)": reviewDictionary, "photoIndex/\(newLocationKey)": photoDictionary]
                // Do a deep-path update
                rootRef.updateChildValues(updatedUserData, withCompletionBlock: { (error, ref) -> Void in
                    if (error != nil) {
                        print("Error updating data: \(String(describing: error))")
                    }
                })
                
            } else {
                // you must be adding a new record
                listItemArray.append(newItem)
                
                // Generate a new push ID for the new location (stored in "items")
                let newLocationRef = rootRef.child("items").child(newItem.listItemKey)
                let newLocationKey = newLocationRef.key
                
                // Create a dictionary of all photo names associated with this location
                var photoDictionary = [String : Any]()
                for fileName in source.locationPhotoFileNames {
                    photoDictionary[fileName] = userEmail
                }
                
                // Create a dictionary of all reviews at this location
                var reviewDictionary = [String : Any]()
                
                for review in (source.listItem?.reviews)! {
                    var ratingsEntry = [String: Any]()
                    ratingsEntry["reviewHeadline"] = review.reviewHeadline
                    ratingsEntry["reviewText"] = review.reviewText
                    ratingsEntry["rating"] = review.rating
                    
                    let newReviewIndexRef = self.reviewsRef.child(newLocationKey).childByAutoId()
                    let newReviewRefKey = newReviewIndexRef.key
                    reviewDictionary["\(newReviewRefKey)"] = ratingsEntry
                }
                
                // Create the data we want to update
                let updatedUserData = ["items/\(newLocationKey)": ["placeName": newItem.placeName, "postedBy": userEmail, "listItemKey": newItem.listItemKey, "latitude": newItem.latitude, "longitude": newItem.longitude, "address": newItem.address], "reviews/\(newLocationKey)": reviewDictionary,"photoIndex/\(newLocationKey)": photoDictionary]
                // Do a deep-path update
                rootRef.updateChildValues(updatedUserData, withCompletionBlock: { (error, ref) -> Void in
                    if (error != nil) {
                        print("Error updating data: \(String(describing: error))")
                    }
                })
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
        cell.textLabel?.text = listItemArray[indexPath.row].placeName
        cell.detailTextLabel?.text = listItemArray[indexPath.row].address
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let listItemKey = listItemArray[indexPath.row].listItemKey
            
            // Read in all files so you can delete them
            let path = "photoIndex/" + listItemKey
            let photosRef = FIRDatabase.database().reference(withPath: path)
            var locationPhotoFileNames = [String]()
            photosRef.observeSingleEvent(of: .value, with: { snapshot in
                for child in snapshot.children {
                    let itemSnapshot = child as! FIRDataSnapshot
                    // let itemValue = itemSnapshot.value as! [String: AnyObject]
                    let fileName = itemSnapshot.key
                    locationPhotoFileNames.append(fileName)
                }
                
                let updatedUserData = ["items/\(listItemKey)": NSNull(), "photoIndex/\(listItemKey)": NSNull()]
                
                // Do a deep-path update
                self.rootRef.updateChildValues(updatedUserData, withCompletionBlock: { (error, ref) -> Void in
                    if (error != nil) {
                        print("Error updating data: \(String(describing: error))")
                    }
                    self.deleteAllPhotosForThisLocation(locationPhotoFileNames: locationPhotoFileNames)
                })
            })
        }
    }
    
    func deleteAllPhotosForThisLocation(locationPhotoFileNames: [String]) {
        
        for fileName in locationPhotoFileNames {
            // Get a reference to the storage service using the default Firebase App
            let storage = FIRStorage.storage()
            // Create a storage reference from our storage service
            let storageRef = storage.reference()
            // Create a reference to the file to delete
            let fileRef = storageRef.child("location_images").child(fileName)
            // Delete the file
            fileRef.delete { error in
                if let error = error {
                    // Uh-oh, an error occurred!
                } else {
                    // File deleted successfully
                }
            }
        }
    }
    
    
}
