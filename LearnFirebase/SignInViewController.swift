//
//  SignInViewController.swift
//  LearnFirebase
//
//  Created by John Gallaugher on 4/16/17.
//  Copyright © 2017 Gallaugher. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SignInViewController: UIViewController, GIDSignInUIDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
    }


}
