//
//  CustomActivityItem.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 18/08/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import UIKit

class CustomActivityItem: NSObject, UIActivityItemSource {
    var shareText: String!
    
    override init() {
        super.init()
        
        shareText = DataModel.getShareText()
    }
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return shareText
    }
    
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        if activityType == UIActivityTypePostToTwitter {
            return DataModel.getShareTextTwitter()
        } else {
            return shareText
        }
    }
}
