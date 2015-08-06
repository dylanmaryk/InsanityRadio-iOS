//
//  PlayerViewController.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 25/05/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import MediaPlayer
import UIKit

class PlayerViewController: UIViewController {
    @IBOutlet weak var currentShowLabel: UILabel!
    @IBOutlet weak var nowPlayingLabel: UILabel!
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var shareBarButtonItem: UIBarButtonItem!
    
    let radio = Radio()
    let manager = AFHTTPRequestOperationManager()
    var currentShow: (day: String, name: String, presenters: String, link: String, imageURL: String)!
    var nowPlayingArtist: String!
    var nowPlayingSong: String!
    var paused: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        radio.connect("http://stream.insanityradio.com:8000/insanity320.mp3", withDelegate: self, withGain: (1.0))
        
        manager.requestSerializer.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: "DataUpdated", object: nil)
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }
    
    func updateUI() {
        currentShow = DataModel.getCurrentShow()
        var currentShowLabelText = currentShow.name
        
        if currentShow.presenters != "" {
            currentShowLabelText += "\nwith " + currentShow.presenters
        }
        
        currentShowLabel.text = currentShowLabelText
        
        nowPlayingLabel.text = nowPlayingArtist + "\n" + nowPlayingSong
        
        var url = "http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=eedbd282e57a31428945d8030a9f3301&artist=" + nowPlayingArtist + "&track=" + nowPlayingSong + "&format=json"
        url = url.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: NSStringCompareOptions.LiteralSearch, range: nil)
        println(url) // Temp
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
            self.displayFinalImage(responseObject as? UIImage)
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            self.displayCurrentShowImage()
        })
        requestOperation.start()
    }
    
    func displayCurrentShowImage() {
        manager.responseSerializer = AFImageResponseSerializer()
        let requestOperation = manager.GET(currentShow.imageURL, parameters: nil, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            self.displayFinalImage(responseObject as? UIImage)
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            self.displayFinalImage(UIImage(named: "insanity-icon.png"))
        })
        requestOperation.start()
    }
    
    func displayFinalImage(image: UIImage?) {
        self.albumArtImageView.image = image
        
        if NSClassFromString("MPNowPlayingInfoCenter") != nil {
            var title: String
            var artist: String
            
            if paused {
                title = "Insanity Radio"
                artist = "103.2FM"
            } else {
                title = nowPlayingSong
                artist = DataModel.getCurrentShow().name
            }
            
            let songInfo = [
                MPMediaItemPropertyTitle: title,
                MPMediaItemPropertyArtist: artist,
                MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image)
            ]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
        }
    }
    
    @IBAction func playPauseButtonTapped() {
        if paused {
            playRadio()
        } else {
            pauseRadio()
        }
    }
    
    func playRadio() {
        playPauseButton.enabled = false
        playPauseButton.alpha = 0.5
        radio.updatePlay(true)
    }
    
    func pauseRadio() {
        radioPaused()
        radio.updatePlay(false)
    }
    
    func radioPlayed() {
        paused = false
        
        playPauseButton.enabled = true
        playPauseButton.alpha = 1
        playPauseButton.imageView?.image = UIImage(named: "stop.png")
    }
    
    func radioPaused() {
        paused = true
        
        playPauseButton.enabled = true
        playPauseButton.alpha = 1
        playPauseButton.imageView?.image = UIImage(named: "play.png")
        currentShowLabel.text = ""
        nowPlayingLabel.text = ""
        displayFinalImage(UIImage(named: "insanity-icon.png"))
    }
    
    @IBAction func shareButtonTapped() {
        let activityViewController = UIActivityViewController(activityItems: [DataModel.getShareText()], applicationActivities: nil)
        
        if activityViewController.respondsToSelector(Selector("popoverPresentationController")) {
            activityViewController.popoverPresentationController?.barButtonItem = shareBarButtonItem
        }
        
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.subtype == UIEventSubtype.RemoteControlPlay {
            playRadio()
        } else if event.subtype == UIEventSubtype.RemoteControlPause {
            pauseRadio()
        }
    }
    
    func metaTitleUpdated(title: NSString) {
        DataModel.updateData()
        var nowPlayingString = title as String!
        nowPlayingString = nowPlayingString.stringByReplacingOccurrencesOfString("StreamTitle='", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        nowPlayingString = nowPlayingString.stringByReplacingOccurrencesOfString("';", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        let nowPlaying = nowPlayingString.componentsSeparatedByString(" - ")
        nowPlayingArtist = nowPlaying[0] as String
        nowPlayingSong = nowPlaying[1] as String
        updateUI()
    }
    
    func connectProblem() {
        radioPaused()
        UIAlertView(title: "Cannot Stream Insanity", message: "There was a problem streaming Insanity Radio. Please check your Internet connection.", delegate: self, cancelButtonTitle: "OK").show()
    }
}
