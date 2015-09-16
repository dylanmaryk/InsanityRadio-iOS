//
//  ShowTableViewCell.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 07/06/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import UIKit

class ShowTableViewCell: UITableViewCell {
    @IBOutlet weak var showTypeView: UIView!
    @IBOutlet weak var showClockLabel: UILabel!
    @IBOutlet weak var showNameLabel: UILabel!
    @IBOutlet weak var showPresentersLabel: UILabel!
    
    func setupCell(show: [String: AnyObject]) {
        if #available(iOS 8.0, *) {
            self.layoutMargins = UIEdgeInsetsZero
        }
        
        if let showType = show["showType"] as? String {
            showTypeView.backgroundColor = colorForShowType(showType)
        }
        
        showClockLabel.text = show["startClock"] as? String
        showNameLabel.text = show["showName"] as? String
        showPresentersLabel.text = show["showPresenters"] as? String
    }
    
    func colorForShowType(showType: String) -> UIColor {
        switch showType {
            case "automated":
                return UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
            case "entertainment":
                return UIColor(red: 255/255, green: 192/255, blue: 0/255, alpha: 1)
            case "specialist":
                return UIColor(red: 146/255, green: 208/255, blue: 80/255, alpha: 1)
            case "talk":
                return UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 1)
            default:
                return UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
        }
    }
}
