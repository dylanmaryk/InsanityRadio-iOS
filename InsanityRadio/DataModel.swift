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
        let nowPlayingData = NSUserDefaults.standardUserDefaults().objectForKey("nowPlaying") as? NSData
        
        if nowPlayingData != nil {
            let nowPlaying = NSKeyedUnarchiver.unarchiveObjectWithData(nowPlayingData!) as! [String: String]
            
            let song = nowPlaying["song"]!
            let artist = nowPlaying["artist"]!
            
            return (song, artist)
        }
        
        return ("", "")
    }
    
    static func getCurrentShow() -> (name: String, presenters: String, link: String, imageURL: String) {
        let currentShowData = NSUserDefaults.standardUserDefaults().objectForKey("currentShow") as? NSData
        
        if currentShowData != nil {
            let currentShow = NSKeyedUnarchiver.unarchiveObjectWithData(currentShowData!) as! [String: String]
            
            let name = currentShow["showName"]!
            let presenters = currentShow["showPresenters"]!
            let link = currentShow["linkURL"]!
            let imageURL = currentShow["imageURL"]!
            
            return (name, presenters, link, imageURL)
        }
        
        return ("", "", "", "")
    }
    
    static func getSchedule() -> [String: [[String: String]]] {
        /*
        let scheduleData = NSUserDefaults.standardUserDefaults().objectForKey("schedule") as? NSData
        
        if scheduleData != nil {
            let schedule = NSKeyedUnarchiver.unarchiveObjectWithData(scheduleData!) as! [String: [[String: String]]]
            
            return schedule
        }
        */
        
        return [String: [[String: String]]]()
    }
    
    static func updateData() {
        let dataJSON = NSData(contentsOfURL: NSURL(string: "http://www.insanityradio.com/app.json")!)
        
        if dataJSON != nil {
            var error = NSError?()
            let dataDict = NSJSONSerialization.JSONObjectWithData(dataJSON!, options: NSJSONReadingOptions.MutableContainers, error: &error) as! NSDictionary
            
            let nowPlaying = dataDict["nowPlaying"] as! [String: String]
            let currentShow = dataDict["currentShow"] as! [String: String]
            let schedule = dataDict["schedule"] as! [String: [[String: String]]]
            
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(nowPlaying), forKey: "nowPlaying")
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(currentShow), forKey: "currentShow")
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(schedule), forKey: "schedule")
        }
    }
}
