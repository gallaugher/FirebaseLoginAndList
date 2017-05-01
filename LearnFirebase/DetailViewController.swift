//
//  DetailViewController.swift
//  LearnFirebase
//
//  Created by John Gallaugher on 4/15/17.
//  Copyright © 2017 Gallaugher. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GooglePlaces
import Firebase

class DetailViewController: UIViewController {
    
    @IBOutlet weak var placeTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var ratingsTableView: UITableView!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var avgRatingLabel: UILabel!
    
    // @IBOutlet weak var postedByLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    var usingUserLocation = false
    let regionRadius = 1000.0 // 1 km
    
    let imagePicker = UIImagePickerController()
    let storageRef = FIRStorage.storage()
    let imagesRef = FIRStorage.storage().reference(withPath: "location_images")
    var uploadTask: FIRStorageUploadTask!
    var photosRef: FIRDatabaseReference!
    var reviewsAtLocationRef: FIRDatabaseReference!
    
    var listItem: ListItem?
    var newLocationRefKey: String?
    var locationPhotoFileNames = [String]()
    var locationImages = [UIImage]()
    var avgRating = 0.0
    
    var reviews = [Review]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        ratingsTableView.delegate = self
        ratingsTableView.dataSource = self
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        if listItem == nil {
            listItem = ListItem()
            listItem?.listItemKey = newLocationRefKey!
            listItem?.postedBy = (FIRAuth.auth()?.currentUser?.email)!
            usingUserLocation = true
            getLocation()
        } else {
            updateUserInterface()
            currentLocation = CLLocation(latitude: (listItem?.latitude)!, longitude: (listItem?.longitude)!)
            updateMap(mapLocation: currentLocation, regionRadius: regionRadius)
        }
        
        let path = "photoIndex/"+(listItem?.listItemKey)!
        photosRef = FIRDatabase.database().reference(withPath: path)
        
        print("photosRef = \(photosRef!)")
        
        // set up observer & load in photo names
        loadFileNames()
        

        reviewsAtLocationRef = FIRDatabase.database().reference(withPath: "reviews").child((listItem?.listItemKey)!)
        
        reviewsAtLocationRef.observe(.value, with: { snapshot in
            self.reviews = []
            for child in snapshot.children {
                var newReviewItem = Review()
                let reviewSnapshot = child as! FIRDataSnapshot
                let reviewValue = reviewSnapshot.value as! [String: AnyObject]
                newReviewItem.reviewHeadline = (reviewValue["reviewHeadline"] as? String ?? "")
                newReviewItem.reviewText = (reviewValue["reviewText"] as? String ?? "")
                newReviewItem.rating = (reviewValue["rating"] as? Int ?? 0)
                newReviewItem.reviewBy = (reviewValue["reviewBy"] as? String ?? "")
                self.reviews.append(newReviewItem)
            }
            self.averageReviews()
            self.ratingsTableView.reloadData()
        })
        
    }
    
    func loadFileNames() {
        
        photosRef!.observe(.value, with: { snapshot in
            self.locationPhotoFileNames = []
            for child in snapshot.children {
                let itemSnapshot = child as! FIRDataSnapshot
                // let itemValue = itemSnapshot.value as! [String: AnyObject]
                let fileName = itemSnapshot.key
                    self.locationPhotoFileNames.append(fileName)
            }
            self.loadInFile()
        })
    }
    
    func loadInFile() {
        for fileName in locationPhotoFileNames {
            locationImages = []
            // Create a reference to the file you want to download
            let fileRef = imagesRef.child(fileName)
            // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
            fileRef.data(withMaxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    print("An error occurred while reading data from fileref: \(fileRef), error: \(error)")
                } else {
                    // Data for "images/island.jpg" is returned
                    let image = UIImage(data: data!)
                    self.locationImages.append(image!)
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func uploadImage(selectedImage: UIImage) {
        let imageName = NSUUID().uuidString // always creates unique string in part based on time/date
        
        // Data in memory
        if let imageData = UIImageJPEGRepresentation(selectedImage, 0.8) {
            // Create a reference to the file you want to upload
            let uploadedImageRef = imagesRef.child(imageName)
            
            // Upload the file to the path "images/rivers.jpg"
            uploadTask = uploadedImageRef.put(imageData, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    return
                }
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata.downloadURL
                self.locationPhotoFileNames.append(imageName)
                self.collectionView.reloadData()
            }
        }
    }
    
    func averageReviews() {
        var averageRating = 0.0
        if reviews.count > 0 {
            for review in reviews {
                averageRating += Double(review.rating)
            }
            averageRating = averageRating/Double(reviews.count)
            averageRating = (round(averageRating * 10))/10
            avgRatingLabel.text = "\(averageRating)"
        } else {
            avgRatingLabel.text = "--"
        }
    }
    
    func updateUserInterface() {
        placeTextField.text = listItem?.placeName
        addressTextField.text = listItem?.address
        // postedByLabel.text = listItem?.postedBy
        averageReviews()
    }
    
    func updateMap(mapLocation: CLLocation, regionRadius: CLLocationDistance) {
        // Set region
        let region = MKCoordinateRegionMakeWithDistance(mapLocation.coordinate, regionRadius, regionRadius)
        mapView.setRegion(region, animated: true)
        
        mapView.removeAnnotations(mapView.annotations)
        
        // Add annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapLocation.coordinate
        annotation.title = listItem?.placeName
        annotation.subtitle = listItem?.address
    
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(mapView.annotations.last!, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "PresentSelectImage":
            print("Yo, I'm pretty much segueing to ShowPhotoSelect")
        case "UnwindFromDetail":
            // Heading back to ListViewController
            listItem?.placeName = placeTextField.text!
            listItem?.latitude = currentLocation.coordinate.latitude
            listItem?.longitude = currentLocation.coordinate.longitude
            listItem?.reviews = reviews
        case "ShowRating":
            let destination = segue.destination as! RatingViewController
            destination.placeName = placeTextField.text
//            destination.review = reviews[(ratingsTableView.indexPathForSelectedRow?.row)!]
            destination.review = reviews[(ratingsTableView.indexPathForSelectedRow?.row)!]
        case "AddRating":
            let destinationNavigationController = segue.destination as! UINavigationController
            let destination = destinationNavigationController.topViewController as! RatingViewController
            // Assign a new location key so this can be used for file names if photos are added.
            destination.placeName = placeTextField.text
            if let selectedRow = ratingsTableView.indexPathForSelectedRow {
                ratingsTableView.deselectRow(at: selectedRow, animated: true)
            }
        default:
            print("An unexpected segue was detected in DetailViewController.swift")
        }
    }
    
    @IBAction func unwindFromImageSelect (sender: UIStoryboardSegue) {
        if let source = sender.source as? SelectImageViewController, let newImage = source.newImage {
            locationImages.append(newImage)
            uploadImage(selectedImage: newImage)
        } else {
            print("Error: Didn't come from SelectImageViewController or couldn't get newImage")
        }
    }
    
    @IBAction func unwindFromRating(sender: UIStoryboardSegue) {
        if let source = sender.source as? RatingViewController, let newReview = source.review {
            reviews.append(newReview)
            averageReviews()
            ratingsTableView.reloadData()
        } else {
            print("Error: Didn't come from SelectImageViewController or couldn't get newImage")
        }
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController!.popViewController(animated: true)
        }
    }
    
    @IBAction func rateButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func currentLocationPressed(_ sender: UIButton) {
        usingUserLocation = true
        getLocation()
    }
    
    @IBAction func googlePlacesPressed(_ sender: UIButton) {
        usingUserLocation = false
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
//    @IBAction func libraryButtonPressed(_ sender: UIButton) {
//        imagePicker.sourceType = .photoLibrary
//        present(imagePicker, animated: true, completion: nil)
//    }
//
//    @IBAction func cameraButtonPressed(_ sender: UIButton) {
//        if UIImagePickerController.isSourceTypeAvailable(.camera) {
//            imagePicker.sourceType = .camera
//            present(imagePicker, animated: true, completion: nil)
//        } else {
//            showAlert(title: "Camera Not Available", message: "There is no camera avaiable on this device.")
//        }
//    }
//    
//    @IBAction func addPhotoButtonPressed(_ sender: UIButton) {
//        
//    }
    
}

extension DetailViewController: MKMapViewDelegate {
    
}

extension DetailViewController: CLLocationManagerDelegate {
    
    // Called from viewDidLoad() to get location when this scene loads
    func getLocation() {
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        let status = CLLocationManager.authorizationStatus()
        handleLocationAuthorizationStatus(status: status)
    }
    
    // Respond to the result of the location manager authorization status
    func handleLocationAuthorizationStatus(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied:
            showAlert(title: "User has not authorized location services", message: "Open the Settings app > Privacy > Location Services > WeatherGift to enable location services in this app.")
        case .restricted:
            showAlert(title: "Location Services Denied", message: "It may be that parental controls are restricting location use in this app.")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // This function is called if status is changed. If so, handle the
    //  status change
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleLocationAuthorizationStatus(status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if usingUserLocation {
            currentLocation = locations.last!
            
            let geoCoder = CLGeocoder()
            
            geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: { (placemarks, error) in
                let placemark = placemarks?.first
                let streetNumber = (placemark?.subThoroughfare ?? "")
                let street = (placemark?.thoroughfare ?? "")
                let city = (placemark?.locality ?? "")
                let state = (placemark?.administrativeArea ?? "")
                let address = "\(streetNumber) \(street), \(city), \(state)"
                
                self.listItem?.placeName = (placemark?.name ?? "")
                self.listItem?.address = address
                
                self.updateUserInterface()
                self.updateMap(mapLocation: self.currentLocation, regionRadius: self.regionRadius)
            })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location. Error code \(error)")
    }
}

extension DetailViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {

        listItem?.placeName = place.name
        listItem?.address = (place.formattedAddress ?? "")
        updateUserInterface()
        currentLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        
        print("GGG in didComplete and currentLocation.coordinates are \(currentLocation.coordinate)")
        
        dismiss(animated: true, completion: { self.updateMap(mapLocation: self.currentLocation, regionRadius: self.regionRadius) } )
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

extension DetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
}

extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locationImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! LocationImageCollectionViewCell
        cell.locationImage.image = locationImages[indexPath.row]
        return cell
    }
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "TableCell") as! RatingTableViewCell
        tableCell.reviewByLabel.text = (FIRAuth.auth()?.currentUser?.email)!
        tableCell.reviewTextLabel.text = reviews[indexPath.row].reviewText
        tableCell.ratingHeadlineLabel.text = reviews[indexPath.row].reviewHeadline
        print("rating = \(reviews[indexPath.row].rating)")
        tableCell.ratingControl.rating = reviews[indexPath.row].rating
        return tableCell
    }
}



