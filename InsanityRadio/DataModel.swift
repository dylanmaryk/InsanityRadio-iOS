//
//  DataModel.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 31/05/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import Foundation

class DataModel {
    static func getCurrentShow() -> (day: String, name: String, presenters: String, link: String, imageURL: String) {
        if let schedule = getSchedule() {
            let calendar = NSCalendar.currentCalendar()
            let currentTimeComponents = calendar.components((.CalendarUnitWeekday | .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond), fromDate: NSDate())
            let showTimeComponents = NSDateComponents()
            showTimeComponents.year = 1982
            showTimeComponents.month = 8
            showTimeComponents.day = currentTimeComponents.weekday
            showTimeComponents.hour = currentTimeComponents.hour
            showTimeComponents.minute = currentTimeComponents.minute
            showTimeComponents.second = currentTimeComponents.second
            let showTimeEpoch = calendar.dateFromComponents(showTimeComponents)?.timeIntervalSince1970
            let showTimeEpochInt = Int(showTimeEpoch!)
            
            let dayString = getDayStringForDayInt(currentTimeComponents.weekday)
            
            if var shows = schedule[dayString] {
                // Add last show of previous day to shows, in case current show started before midnight
                
                var weekdayYesterdayInt = currentTimeComponents.weekday - 1
                
                if (weekdayYesterdayInt == 0) {
                    weekdayYesterdayInt = 7
                }
                
                let dayYesterdayString = getDayStringForDayInt(weekdayYesterdayInt)
                
                if let showsYesterday = schedule[dayYesterdayString] where !showsYesterday.isEmpty {
                    shows.append(showsYesterday.last!)
                }
                
                for show in shows {
                    if let startTime = show["startTime"] as? Int,
                        let endTime = show["endTime"] as? Int {
                        // Note: Making assumption that if the last show of the week ends after the end of the week, it ends when the first show of the week begins
                        let showEndsAfterEndOfWeek = endTime > 397609200
                        
                        if (startTime <= showTimeEpochInt + 1 && endTime > showTimeEpochInt) || showEndsAfterEndOfWeek,
                            let showName = show["showName"] as? String,
                            showPresenters = show["showPresenters"] as? String,
                            linkURL = show["linkURL"] as? String,
                            imageURL = show["imageURL"] as? String {
                            return (dayString, showName, showPresenters, linkURL, imageURL)
                        }
                    }
                }
            }
        }
        
        return ("", "", "", "", "")
    }
    
    static func getDayStringForDayInt(day: Int) -> String {
        switch day {
            case 1:
                return "sunday"
            case 2:
                return "monday"
            case 3:
                return "tuesday"
            case 4:
                return "wednesday"
            case 5:
                return "thursday"
            case 6:
                return "friday"
            case 7:
                return "saturday"
            default:
                return ""
        }
    }
    
    static func getNowPlaying() -> (song: String, artist: String) {
        if let nowPlayingData = NSUserDefaults.standardUserDefaults().objectForKey("nowPlaying") as? NSData {
            let nowPlaying = NSKeyedUnarchiver.unarchiveObjectWithData(nowPlayingData) as! [String: String]
            
            let song = nowPlaying["song"]!
            let artist = nowPlaying["artist"]!
            
            return (song, artist)
        }
        
        return ("", "")
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
        
        return "I'm listening to Insanity Radio via the Insanity Radio 103.2FM app www.insanityradio.com/listen"
    }
    
    static func getShareTextTwitter() -> String {
        if let shareTextTwitterData = NSUserDefaults.standardUserDefaults().objectForKey("shareTextTwitter") as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(shareTextTwitterData) as! String
        }
        
        return "I'm listening to @InsanityRadio via the Insanity Radio 103.2FM app www.insanityradio.com/listen"
    }
    
    static func getEnableComment() -> Bool {
        if let enableCommentData = NSUserDefaults.standardUserDefaults().objectForKey("enableComment") as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(enableCommentData) as! Bool
        }
        
        return true
    }
    
    static func updateData() {
        let manager = AFHTTPRequestOperationManager()
        manager.requestSerializer.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        manager.responseSerializer = AFJSONResponseSerializer()
        let requestOperation = manager.GET("http://www.insanityradio.com/app.json", parameters: nil, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            if let nowPlaying = responseObject["nowPlaying"] as? [String: String] {
                self.setUserDefaultsObjectArchived(nowPlaying, forKey: "nowPlaying")
            }
            
            if let schedule = responseObject["schedule"] as? [String: [[String: AnyObject]]] {
                self.setUserDefaultsObjectArchived(schedule, forKey: "schedule")
            }
            
            if let shareText = responseObject["shareText"] as? String {
                self.setUserDefaultsObjectArchived(shareText, forKey: "shareText")
            }
            
            if let shareTextTwitter = responseObject["shareTextTwitter"] as? String {
                self.setUserDefaultsObjectArchived(shareTextTwitter, forKey: "shareTextTwitter")
            }
            
            if let enableComment = responseObject["enableComment"] as? Bool {
                self.setUserDefaultsObjectArchived(enableComment, forKey: "enableComment")
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName("DataUpdated", object: nil)
            }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                
        })
        requestOperation.start()
    }
    
    static func setUserDefaultsObjectArchived(object: AnyObject, forKey key: String) {
        NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(object), forKey: key)
    }
}
