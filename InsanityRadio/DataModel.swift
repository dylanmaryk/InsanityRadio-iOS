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
        if let currentShowData = NSUserDefaults.standardUserDefaults().objectForKey("currentShow") as? NSData {
            let currentShow = NSKeyedUnarchiver.unarchiveObjectWithData(currentShowData) as! [String: String]
            
            let day = currentShow["dayOfTheWeek"]!
            let name = currentShow["showName"]!
            let presenters = currentShow["showPresenters"]!
            let link = currentShow["linkURL"]!
            let imageURL = currentShow["imageURL"]!
            
            return (day, name, presenters, link, imageURL)
        }
        
        return ("", "", "", "", "")
    }
    
    static func getSchedule() -> [String: [[String: String]]]? {
        if let scheduleData = NSUserDefaults.standardUserDefaults().objectForKey("schedule") as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(scheduleData) as? [String: [[String: String]]]
        }
        
        return nil
    }
    
    static func updateData() {
        let manager = AFHTTPRequestOperationManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        let requestOperation = manager.GET("http://www.insanityradio.com/app.json", parameters: nil, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            let nowPlaying = responseObject["nowPlaying"] as? [String: String]
            let currentShow = responseObject["currentShow"] as? [String: String]
            let schedule = responseObject["schedule"] as? [String: [[String: String]]]
            
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(nowPlaying!), forKey: "nowPlaying")
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(currentShow!), forKey: "currentShow")
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(schedule!), forKey: "schedule")
            
            NSNotificationCenter.defaultCenter().postNotificationName("DataUpdated", object: nil)
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            
        })
        requestOperation.start()
    }
}
