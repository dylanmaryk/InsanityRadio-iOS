//
//  ScheduleViewController.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 25/05/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import UIKit

class ScheduleViewController: UIViewController {
    var schedule: [String: [[String: String]]] = [String: [[String: String]]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        schedule = DataModel.getSchedule()
    }
}
