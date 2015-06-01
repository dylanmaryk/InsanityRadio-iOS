//
//  PlayerViewController.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 25/05/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let player = Radio()
        player.connect("http://stream.insanityradio.com:8000/insanity320.mp3", withDelegate: self, withGain: (1.0))
    }
    
    func updateUI() {
        let nowPlaying = DataModel.getNowPlaying()
        
        // Update labels
        
        let currentShow = DataModel.getCurrentShow()
        
        // Get image, update labels
    }
    
    func metaTitleUpdated(title: NSString) {
        DataModel.updateData()
        updateUI()
    }
}
