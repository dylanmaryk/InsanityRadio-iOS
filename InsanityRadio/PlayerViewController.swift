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
        let dataDict = DataModel.getData()
        
        let nowPlaying: NSDictionary = dataDict["nowPlaying"] as! NSDictionary
        let nowPlayingSong: String = nowPlaying["song"] as! String
        let nowPlayingArtist: String = nowPlaying["artist"] as! String
        
        let currentShow: NSDictionary = dataDict["currentShow"] as! NSDictionary
        let currentShowName: String = currentShow["showName"] as! String
        let currentShowPresenters: String = currentShow["showPresenters"] as! String
        let currentShowLink: String = currentShow["linkURL"] as! String
        let currentShowImage: String = currentShow["imageURL"] as! String
        
        // Update labels, images etc.
    }
    
    func metaTitleUpdated(title: NSString) {
        updateUI()
    }
}
