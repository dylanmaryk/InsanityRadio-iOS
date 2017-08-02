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
            let currentTimeComponents = calendar.components([.Weekday, .Hour, .Minute, .Second], fromDate: NSDate())
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
    
    private static func getDayStringForDayInt(day: Int) -> String {
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
    
    static func getNowPlaying() -> (song: String, artist: String, albumArt: String?) {
        guard let nowPlayingData = NSUserDefaults.standardUserDefaults().objectForKey("nowPlaying") as? NSData else {
            return ("", "", "")
        }
        
        let nowPlaying = NSKeyedUnarchiver.unarchiveObjectWithData(nowPlayingData) as? [String: AnyObject]
        
        let song = nowPlaying!["song"] as! String
        let artist = nowPlaying!["artist"] as! String
        
        let albumArt = nowPlaying!["album_art"] as? String
        
        return (song, artist, albumArt)
    }
    
    static func getSchedule() -> [String: [[String: AnyObject]]]? {
        guard let scheduleData = NSUserDefaults.standardUserDefaults().objectForKey("schedule") as? NSData else {
            return nil
        }
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(scheduleData) as? [String: [[String: AnyObject]]]
    }
    
    static func getShareText() -> String {
        guard let shareTextData = NSUserDefaults.standardUserDefaults().objectForKey("shareText") as? NSData else {
            return "I'm listening to Insanity Radio via the Insanity Radio 103.2FM app https://insanityradio.com/listen/"
        }
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(shareTextData) as! String
    }
    
    static func getShareTextTwitter() -> String {
        guard let shareTextTwitterData = NSUserDefaults.standardUserDefaults().objectForKey("shareTextTwitter") as? NSData else {
            return "I'm listening to @InsanityRadio via the Insanity Radio 103.2FM app https://insanityradio.com/listen/"
        }
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(shareTextTwitterData) as! String
    }
    
    static func getEnableComment() -> Bool {
        guard let enableCommentData = NSUserDefaults.standardUserDefaults().objectForKey("enableComment") as? NSData else {
            return true
        }
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(enableCommentData) as! Bool
    }
    
    static func updateData() {
        let manager = AFHTTPRequestOperationManager()
        manager.requestSerializer.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        manager.responseSerializer = AFJSONResponseSerializer()
        let requestOperation = manager.GET("https://insanityradio.com/listen/load_status.json?v=" + API_VERSION, parameters: nil, success: {(operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            if let nowPlaying = responseObject["nowPlaying"] as? [String: AnyObject] {
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
        }, failure: {(operation: AFHTTPRequestOperation?, error: NSError) -> Void in
            
        })
        requestOperation!.start()
    }
    
    private static func setUserDefaultsObjectArchived(object: AnyObject, forKey key: String) {
        NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(object), forKey: key)
    }
}
