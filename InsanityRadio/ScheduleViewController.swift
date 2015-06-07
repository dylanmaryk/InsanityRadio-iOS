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
            scheduleTableView.hidden = true
            UIAlertView(title: "Cannot Download Schedule", message: "Please connect to the Internet to see the schedule.", delegate: self, cancelButtonTitle: "OK").show()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if schedule != nil  {
            let currentShowDay = DataModel.getCurrentShow().day
            scheduleTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: sectionForDay(currentShowDay)), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
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
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.respondsToSelector("setSeparatorInset:") {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if cell.respondsToSelector("setPreservesSuperviewLayoutMargins:") {
            cell.preservesSuperviewLayoutMargins = false
        }
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
    
    func sectionForDay(day: String) -> Int {
        switch day {
            case "monday":
                return 0
            case "tuesday":
                return 1
            case "wednesday":
                return 2
            case "thursday":
                return 3
            case "friday":
                return 4
            case "saturday":
                return 5
            case "sunday":
                return 6
            default:
                return 0
        }
    }
    
    func dayForSection(section: Int) -> String {
        switch section {
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
