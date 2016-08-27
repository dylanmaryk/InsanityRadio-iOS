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
    
    private var schedule: [String: [[String: AnyObject]]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateUI), name: "DataUpdated", object: nil)
        
        scheduleTableView.contentInset = UIEdgeInsetsMake(0, 0, self.tabBarController!.tabBar.frame.size.height, 0);
        scheduleTableView.scrollIndicatorInsets = scheduleTableView.contentInset
        
        updateUI()
    }
    
    func updateUI() {
        schedule = DataModel.getSchedule()
        
        if schedule != nil {
            scheduleTableView.hidden = false
            scheduleTableView.reloadData()
        } else {
            scheduleTableView.hidden = true
            UIAlertView(title: "Cannot Download Schedule", message: "There was a problem downloading the schedule. Please check your Internet connection.", delegate: self, cancelButtonTitle: "OK").show()
        }
        
        if numberOfSectionsInTableView(scheduleTableView) > 0 {
            let currentShowDay = DataModel.getCurrentShow().day
            let sectionForCurrentShowDay = sectionForDay(currentShowDay)
            scheduleTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: sectionForCurrentShowDay), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        guard let validSchedule = schedule else {
            return 0
        }
        
        return validSchedule.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dayForSection(section).capitalizedString
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let validSchedule = schedule,
            scheduleDay = validSchedule[dayForSection(section)] else {
                return 0
        }
        
        return scheduleDay.count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.respondsToSelector(Selector("setSeparatorInset:")) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if #available(iOS 8.0, *) {
            cell.preservesSuperviewLayoutMargins = false
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let showCell = tableView.dequeueReusableCellWithIdentifier("ShowCell", forIndexPath: indexPath) as! ShowTableViewCell
        showCell.setupCell(showForIndexPath(indexPath))
        
        return showCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let linkURL = showForIndexPath(indexPath)["linkURL"] as? String else {
            return
        }
        
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
    
    func showForIndexPath(indexPath: NSIndexPath) -> [String: AnyObject] {
        guard let validSchedule = schedule,
            scheduleDay = validSchedule[dayForSection(indexPath.section)] else {
                return [:]
        }
        
        return scheduleDay[indexPath.row]
    }
}
