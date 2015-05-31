//
//  DataModel.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 31/05/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import Foundation

class DataModel {
    static func getData() -> NSDictionary {
        let dataJson = NSData(contentsOfURL: NSURL(string: "http://insanityradio.com/app.json")!)
        var error = NSError?()
        let dataDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(dataJson!, options: NSJSONReadingOptions.MutableContainers, error: &error) as! NSDictionary
        
        return dataDict
    }
}
