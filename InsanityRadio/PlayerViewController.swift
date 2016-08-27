//
//  PlayerViewController.swift
//  InsanityRadio
//
//  Created by Dylan Maryk on 25/05/2015.
//  Copyright (c) 2015 Insanity Radio. All rights reserved.
//

import MediaPlayer
import UIKit

class PlayerViewController: UIViewController, RadioDelegate {
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var shareBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var currentShowLabel: UILabel!
    @IBOutlet weak var nowPlayingLabel: UILabel!
    @IBOutlet weak var albumArtImageView: UIImageView!
    
    private let radio = Radio()
    private let manager = AFHTTPRequestOperationManager()
    private var previousNowPlayingArtwork: UIImage?
    private var paused = true
    private var attemptingPlay = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        radio.connect("http://stream.insanityradio.com:8000/insanity320.mp3", withDelegate: self, withGain: (1.0))
        
        manager.requestSerializer.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateUI), name: "DataUpdated", object: nil)
        
        // Workaround for play/stop button image changing on rotate on iOS 9
        if #available(iOS 9.0, *) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updatePlayPauseButton), name: UIDeviceOrientationDidChangeNotification, object: nil)
        }
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        NSTimeZone.setDefaultTimeZone(NSTimeZone(name: "Europe/London")!)
        
        // Test if timer retained in background until app terminated by system
        let components = NSCalendar.currentCalendar().components([.Minute, .Second], fromDate: NSDate())
        let secondsUntilNextHour = NSTimeInterval(3600 - (components.minute * 60) - components.second)
        NSTimer.scheduledTimerWithTimeInterval(secondsUntilNextHour, target: self, selector: #selector(startCurrentShowTimer), userInfo: nil, repeats: false)
        
        let titleViewImageView = UIImageView(frame: CGRectMake(0, 0, 35, 35))
        titleViewImageView.image = UIImage(named: "headphone")
        let titleViewLabel = UILabel()
        titleViewLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 17)
        titleViewLabel.textColor = UIColor.whiteColor()
        titleViewLabel.text = "Insanity Radio"
        let titleViewLabelSize = titleViewLabel.sizeThatFits(CGSizeMake(CGFloat.max, titleViewImageView.frame.size.height))
        titleViewLabel.frame = CGRectMake(titleViewImageView.frame.size.width + 10, 0, titleViewLabelSize.width, titleViewImageView.frame.size.height)
        let titleView = UIView(frame: CGRectMake(0, 0, titleViewLabel.frame.origin.x + titleViewLabel.frame.size.width, titleViewLabel.frame.size.height))
        titleView.addSubview(titleViewImageView)
        titleView.addSubview(titleViewLabel)
        navItem.titleView = titleView
        
        playPauseButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        
        enableDisableComment()
        
        updateCurrentShow()
    }
    
    func updateUI() {
        enableDisableComment()
        
        updateCurrentShow()
        
        let nowPlaying = DataModel.getNowPlaying()
        nowPlayingLabel.text = nowPlaying.artist + "\n" + nowPlaying.song
        
        var url = "http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=" + LASTFM_API_KEY + "&artist=" + nowPlaying.artist + "&track=" + nowPlaying.song + "&autocorrect&format=json"
        url = url.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: NSStringCompareOptions.LiteralSearch, range: nil)
        manager.responseSerializer = AFJSONResponseSerializer()
        let requestOperation = manager.GET(url, parameters: nil, success: { (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            self.updateImageWithResponse(responseObject)
        }, failure: { (operation: AFHTTPRequestOperation?, error: NSError) -> Void in
            self.displayCurrentShowImage()
        })
        requestOperation!.start()
        
        radioPlayed()
        displayNowPlayingInfo(previousNowPlayingArtwork)
    }
    
    private func enableDisableComment() {
        if DataModel.getEnableComment() {
            commentButton.hidden = false
        } else {
            commentButton.hidden = true
        }
    }
    
    func updateCurrentShow() {
        let currentShow = DataModel.getCurrentShow()
        var currentShowLabelText = currentShow.name
        
        if currentShow.presenters != "" {
            currentShowLabelText += "\nwith " + currentShow.presenters
        }
        
        currentShowLabel.text = currentShowLabelText
    }
    
    private func updateImageWithResponse(responseObject: AnyObject) {
        if let track = responseObject["track"] as? [String: AnyObject],
            let album = track["album"] as? [String: AnyObject],
            let images = album["image"] as? [[String: String]] {
            for image in images {
                if let text = image["#text"] where image["size"] == "extralarge" {
                    updateImageWithURL(text)
                    
                    return
                }
            }
        }
        
        displayCurrentShowImage()
    }
    
    private func updateImageWithURL(imageURL: String) {
        manager.responseSerializer = AFImageResponseSerializer()
        let requestOperation = manager.GET(imageURL, parameters: nil, success: { (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            self.displayFinalImage(responseObject as? UIImage)
        }, failure: { (operation: AFHTTPRequestOperation?, error: NSError) -> Void in
            self.displayCurrentShowImage()
        })
        requestOperation!.start()
    }
    
    private func displayCurrentShowImage() {
        manager.responseSerializer = AFImageResponseSerializer()
        let requestOperation = manager.GET(DataModel.getCurrentShow().imageURL, parameters: nil, success: { (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            self.displayFinalImage(responseObject as? UIImage)
        }, failure: { (operation: AFHTTPRequestOperation?, error: NSError) -> Void in
            self.displayDefaultImage()
        })
        requestOperation!.start()
    }
    
    private func displayFinalImage(image: UIImage?) {
        self.albumArtImageView.image = image
        displayNowPlayingInfo(image);
    }
    
    private func displayDefaultImage() {
        self.albumArtImageView.image = UIImage(named: "insanity-icon.png")
        displayNowPlayingInfo(nil);
    }
    
    private func displayNowPlayingInfo(image: UIImage?) {
        if NSClassFromString("MPNowPlayingInfoCenter") == nil {
            return
        }
        
        previousNowPlayingArtwork = image
        
        let nowPlaying = DataModel.getNowPlaying()
        let currentShow = DataModel.getCurrentShow()
        
        var nowPlayingSong: String
        var currentShowName: String
        
        if paused {
            nowPlayingSong = "Insanity Radio"
        } else {
            nowPlayingSong = nowPlaying.song
        }
        
        if currentShow.name == "" {
            currentShowName = "103.2FM"
        } else {
            currentShowName = currentShow.name
        }
        
        var songInfo: [String: AnyObject] = [
            MPMediaItemPropertyTitle: nowPlayingSong,
            MPMediaItemPropertyArtist: currentShowName
        ]
        
        if let nowPlayingImage = image {
            songInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: nowPlayingImage)
        }
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
    }
    
    @IBAction private func playPauseButtonTapped() {
        if paused {
            playRadio()
        } else {
            pauseRadio()
        }
    }
    
    private func playRadio() {
        attemptingPlay = true
        
        playPauseButton.enabled = false
        playPauseButton.alpha = 0.5
        radio.updatePlay(true)
    }
    
    private func pauseRadio() {
        radioPaused()
        radio.updatePlay(false)
    }
    
    func updatePlayPauseButton() {
        if attemptingPlay {
            playPauseButton.enabled = false
            playPauseButton.alpha = 0.5
        } else if paused {
            radioPaused()
        } else {
            radioPlayed()
        }
    }
    
    private func radioPlayed() {
        paused = false
        attemptingPlay = false
        
        playPauseButton.enabled = true
        playPauseButton.alpha = 1
        playPauseButton.imageView?.image = UIImage(named: "stop.png")
    }
    
    private func radioPaused() {
        paused = true
        attemptingPlay = false
        
        playPauseButton.enabled = true
        playPauseButton.alpha = 1
        playPauseButton.imageView?.image = UIImage(named: "play.png")
        nowPlayingLabel.text = ""
        displayDefaultImage()
    }
    
    @IBAction private func commentButtonTapped() {
        let entity = SocializeEntity(key: "insanityradio")
        SZCommentUtils.showCommentsListWithViewController(self, entity: entity, completion: nil)
    }
    
    @IBAction private func shareButtonTapped() {
        let activityViewController = UIActivityViewController(activityItems: [CustomActivityItem()], applicationActivities: nil)
        
        if #available(iOS 8.0, *) {
            activityViewController.popoverPresentationController?.barButtonItem = shareBarButtonItem
        }
        
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    func startCurrentShowTimer() {
        NSTimer.scheduledTimerWithTimeInterval(3600, target: self, selector: #selector(updateCurrentShow), userInfo: nil, repeats: true)
        updateCurrentShow()
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        guard let controlEvent = event else {
            return
        }
        
        if controlEvent.subtype == UIEventSubtype.RemoteControlPlay {
            playRadio()
        } else if controlEvent.subtype == UIEventSubtype.RemoteControlPause {
            pauseRadio()
        }
    }
    
    func metaTitleUpdated(title: String) {
        DataModel.updateData()
    }
    
    func interruptRadio() {
        pauseRadio()
    }
    
    func resumeInterruptedRadio() {
        playRadio()
    }
    
    func connectProblem() {
        radioPaused()
        UIAlertView(title: "Cannot Stream Insanity", message: "There was a problem streaming Insanity Radio. Please check your Internet connection.", delegate: self, cancelButtonTitle: "OK").show()
    }
}
