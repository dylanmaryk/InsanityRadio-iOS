//
//  DataModel.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 31/05/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import Foundation

class DataModel {
    static func getNowPlaying() -> (song: String, artist: String) {
        if let nowPlayingData = NSUserDefaults.standardUserDefaults().objectForKey("nowPlaying") as? NSData {
            let nowPlaying = NSKeyedUnarchiver.unarchiveObjectWithData(nowPlayingData) as! [String: String]
            
            let song = nowPlaying["song"]!
            let artist = nowPlaying["artist"]!
            
            return (song, artist)
        }
        
        return ("", "")
    }
    
    static func getCurrentShow() -> (day: String, name: String, presenters: String, link: String, imageURL: String) {
        if let schedule = getSchedule() {
            let calendar = NSCalendar.currentCalendar()
            let currentTimeComponents = calendar.components((.CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond), fromDate: NSDate())
            let showTimeComponents = NSDateComponents()
            showTimeComponents.second = currentTimeComponents.second
            showTimeComponents.minute = currentTimeComponents.minute
            showTimeComponents.hour = currentTimeComponents.hour
            showTimeComponents.day = 1
            showTimeComponents.month = 8
            showTimeComponents.year = 1982
            let showTimeEpoch = calendar.dateFromComponents(showTimeComponents)?.timeIntervalSince1970
            let showTimeEpochInt = Int(showTimeEpoch!)
            
            // Optimise to only iterate through shows in current day, need to get day based on date
            for (dayKey, dayValue) in schedule {
                for show in dayValue {
                    if let startTime = show["startTime"] as? Int where startTime < showTimeEpochInt,
                        let endTime = show["endTime"] as? Int where endTime > showTimeEpochInt {
                        return (dayKey, show["showName"] as! String, show["showPresenters"] as! String, show["linkURL"] as! String, show["imageURL"] as! String)
                    }
                }
            }
        }
        
        return ("", "", "", "", "")
    }
    
    static func getSchedule() -> [String: [[String: AnyObject]]]? {
        if let scheduleData = NSUserDefaults.standardUserDefaults().objectForKey("schedule") as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(scheduleData) as? [String: [[String: AnyObject]]]
        }
        
        return nil
    }
    
    static func getShareText() -> String {
        if let shareTextData = NSUserDefaults.standardUserDefaults().objectForKey("shareText") as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(shareTextData) as! String
        }
        
        // Determine final default text before release
        return "I'm listening to Insanity Radio via the Insanity Radio 103.2FM app www.insanityradio.com/listen"
    }
    
    static func updateData() {
        let manager = AFHTTPRequestOperationManager()
        manager.requestSerializer.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        manager.responseSerializer = AFJSONResponseSerializer()
        let requestOperation = manager.GET("http://www.insanityradio.com/app.json", parameters: nil, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            let nowPlaying = responseObject["nowPlaying"] as? [String: String]
            let schedule = responseObject["schedule"] as? [String: [[String: AnyObject]]]
            let shareText =  responseObject["shareText"] as? String
            
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(nowPlaying!), forKey: "nowPlaying")
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(schedule!), forKey: "schedule")
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(shareText!), forKey: "shareText")
            
            NSNotificationCenter.defaultCenter().postNotificationName("DataUpdated", object: nil)
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            
        })
        requestOperation.start()
    }
}
