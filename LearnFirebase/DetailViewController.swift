//
//  DetailViewController.swift
//  LearnFirebase
//
//  Created by John Gallaugher on 4/15/17.
//  Copyright © 2017 Gallaugher. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var itemTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var listItem: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if listItem != nil {
            itemTextField.text = listItem
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        listItem = itemTextField.text
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
