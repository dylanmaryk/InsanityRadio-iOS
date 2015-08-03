//
//  PlayerViewController.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 25/05/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController {
    @IBOutlet weak var currentShowLabel: UILabel!
    @IBOutlet weak var nowPlayingLabel: UILabel!
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    
    let radio = Radio()
    let manager = AFHTTPRequestOperationManager()
    var currentShow: (day: String, name: String, presenters: String, link: String, imageURL: String)!
    var paused: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        radio.connect("http://stream.insanityradio.com:8000/insanity320.mp3", withDelegate: self, withGain: (1.0))
        
        manager.requestSerializer.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData;
    }
    
    func updateUI() {
        currentShow = DataModel.getCurrentShow()
        var currentShowLabelText = currentShow.name
        
        if currentShow.presenters != "" {
            currentShowLabelText += "\nwith " + currentShow.presenters
        }
        
        currentShowLabel.text = currentShowLabelText
        
        let nowPlaying = DataModel.getNowPlaying()
        nowPlayingLabel.text = nowPlaying.artist + "\n" + nowPlaying.song
        
        var url = "http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=eedbd282e57a31428945d8030a9f3301&artist=" + nowPlaying.artist + "&track=" + nowPlaying.song + "&format=json"
        url = url.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: NSStringCompareOptions.LiteralSearch, range: nil)
        manager.responseSerializer = AFJSONResponseSerializer()
        let requestOperation = manager.GET(url, parameters: nil, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            self.updateImageWithResponse(responseObject)
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            self.displayCurrentShowImage()
        })
        requestOperation.start()
        
        radioPlayed()
    }
    
    func updateImageWithResponse(responseObject: AnyObject) {
        if let track = responseObject["track"] as? [String: AnyObject],
            album = track["album"] as? [String: AnyObject],
            images = album["image"] as? [[String: String]] {
            for image in images {
                if image["size"] == "extralarge" {
                    updateImageWithURL(image["#text"])
                    
                    return
                }
            }
        }
        
        displayCurrentShowImage()
    }
    
    func updateImageWithURL(imageURL: String?) {
        manager.responseSerializer = AFImageResponseSerializer()
        let requestOperation = manager.GET(imageURL, parameters: nil, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            self.albumArtImageView.image = responseObject as? UIImage
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            self.displayCurrentShowImage()
        })
        requestOperation.start()
    }
    
    func displayCurrentShowImage() {
        manager.responseSerializer = AFImageResponseSerializer()
        let requestOperation = manager.GET(currentShow.imageURL, parameters: nil, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            self.albumArtImageView.image = responseObject as? UIImage
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            self.albumArtImageView.image = UIImage(named: "insanity-icon.png")
        })
        requestOperation.start()
    }
    
    @IBAction func stopButtonTapped() {
        radioStopped()
        // Stop radio
    }
    
    @IBAction func playPauseButtonTapped() {
        if paused {
            radio.updatePlay(true)
        } else {
            radioPaused()
            radio.updatePlay(false)
        }
    }
    
    func radioStopped() {
        paused = true
        
        stopButton.enabled = false
        stopButton.alpha = 0.5
        playPauseButton.enabled = true
        playPauseButton.alpha = 1
        playPauseButton.imageView?.image = UIImage(named: "play.png")
    }
    
    func radioPlayed() {
        paused = false
        
        stopButton.enabled = true
        stopButton.alpha = 1
        playPauseButton.enabled = true
        playPauseButton.alpha = 1
        playPauseButton.imageView?.image = UIImage(named: "pause.png")
    }
    
    func radioPaused() {
        paused = true
        
        stopButton.enabled = true
        stopButton.alpha = 1
        playPauseButton.enabled = true
        playPauseButton.alpha = 1
        playPauseButton.imageView?.image = UIImage(named: "play.png")
    }
    
    func metaTitleUpdated(title: NSString) {
        DataModel.updateData()
        updateUI()
    }
    
    func connectProblem() {
        currentShowLabel.text = ""
        nowPlayingLabel.text = ""
        albumArtImageView.image = UIImage(named: "insanity-icon.png")
        radioStopped()
        UIAlertView(title: "Cannot Stream Insanity", message: "There was a problem streaming Insanity Radio. Please check your Internet connection.", delegate: self, cancelButtonTitle: "OK").show()
    }
}
