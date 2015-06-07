//
//  ScheduleViewController.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 25/05/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import UIKit

class ScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var scheduleTableView: UITableView!
    
    var schedule: [String: [[String: String]]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        schedule = DataModel.getSchedule()
        
        if schedule == nil {
            // Show error message, hide table view?
        }
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if schedule != nil {
            return schedule!.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dayForSection(section).capitalizedString
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedule![dayForSection(section)]!.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 54
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let showCell = tableView.dequeueReusableCellWithIdentifier("ShowCell", forIndexPath: indexPath) as! ShowTableViewCell
        showCell.setupCell(showForIndexPath(indexPath))
        
        return showCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let linkURL = showForIndexPath(indexPath)["linkURL"]!
        UIApplication.sharedApplication().openURL(NSURL(string: linkURL)!)
    }
    
    func dayForSection(day: Int) -> String {
        switch day {
            case 0:
                return "monday"
            case 1:
                return "tuesday"
            case 2:
                return "wednesday"
            case 3:
                return "thursday"
            case 4:
                return "friday"
            case 5:
                return "saturday"
            case 6:
                return "sunday"
            default:
                return ""
        }
    }
    
    func showForIndexPath(indexPath: NSIndexPath) -> [String: String] {
        return schedule![dayForSection(indexPath.section)]![indexPath.row]
    }
}
