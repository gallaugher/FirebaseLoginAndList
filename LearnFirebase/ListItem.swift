//
//  ListItem.swift
//  LearnFirebase
//
//  Created by John Gallaugher on 4/16/17.
//  Copyright © 2017 Gallaugher. All rights reserved.
//

import Foundation

class ListItem {
    var placeName = ""
    var postedBy = ""
    var listItemKey = ""
    var latitude = 0.0
    var longitude = 0.0
    var address = ""
    var reviews = [Review]()
}
