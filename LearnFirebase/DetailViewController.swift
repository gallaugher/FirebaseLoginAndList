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
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var photoButton: NSLayoutConstraint!
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var postedByLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    var usingUserLocation = false
    let regionRadius = 1000.0 // 1 km
    
    let imagePicker = UIImagePickerController()
    let storageRef = FIRStorage.storage()
    let imagesRef = FIRStorage.storage().reference(withPath: "location_images")
    var uploadTask: FIRStorageUploadTask!
    var photosRef: FIRDatabaseReference!
    
    var listItem: ListItem?
    var newLocationRefKey: String?
    var locationPhotoFileNames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.delegate = self
        
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
            
            // Create a reference to the file you want to download
            let fileRef = imagesRef.child(fileName)
            // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
            fileRef.data(withMaxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    print("An error occurred while reading data from fileref: \(fileRef), error: \(error)")
                } else {
                    // Data for "images/island.jpg" is returned
                    let image = UIImage(data: data!)
                    self.image1.image = image
                }
            }
        }
    }
    
    func updateUserInterface() {
        placeTextField.text = listItem?.placeName
        addressTextField.text = listItem?.address
        postedByLabel.text = listItem?.postedBy
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
        listItem?.placeName = placeTextField.text!
        listItem?.latitude = currentLocation.coordinate.latitude
        listItem?.longitude = currentLocation.coordinate.longitude
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController!.popViewController(animated: true)
        }
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
    
    @IBAction func libraryButtonPressed(_ sender: UIButton) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func cameraButtonPressed(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        } else {
            showAlert(title: "Camera Not Available", message: "There is no camera avaiable on this device.")
        }
    }
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImage: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info ["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImage = originalImage
        }
        
        if let selectedImage = selectedImage {
            image1.image = selectedImage
            uploadImage(selectedImage: selectedImage)
        }
        
        dismiss(animated: true, completion: nil)
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
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}


