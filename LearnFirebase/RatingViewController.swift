//
//  RatingViewController.swift
//  LearnFirebase
//
//  Created by John Gallaugher on 5/1/17.
//  Copyright © 2017 Gallaugher. All rights reserved.
//

import UIKit

class RatingViewController: UIViewController {

    @IBOutlet weak var cancelOrBackButton: UIBarButtonItem!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var reviewTitle: UITextField!
    @IBOutlet weak var reviewText: UITextView!
    @IBOutlet weak var ratingControl: RatingControl!
    
    var review: Review!
    var placeName: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        if review != nil {
            cancelOrBackButton.title = "< Back"
            saveBarButton.title = ""
            saveBarButton.isEnabled = false
            updateUserInterface()
        } else {
            review = Review()
            cancelOrBackButton.title = "Cancel"
            saveBarButton.title = "Save"
            saveBarButton.isEnabled = true
            reviewText.text = ""
        }
    }

    func updateUserInterface() {
        reviewTitle.text = review.reviewHeadline
        reviewText.text = review.reviewText
        ratingControl.rating = review.rating
        placeNameLabel.text = placeName
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let currentRating = ratingControl.rating
        review.rating = currentRating
        review.reviewHeadline = reviewTitle.text!
        review.reviewText = reviewText.text
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController!.popViewController(animated: true)
        }
    }
}
