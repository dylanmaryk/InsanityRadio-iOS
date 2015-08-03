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
    
    var currentShow: (day: String, name: String, presenters: String, link: String, imageURL: String)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let player = Radio()
        player.connect("http://stream.insanityradio.com:8000/insanity320.mp3", withDelegate: self, withGain: (1.0))
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
        println(url)
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let operation = AFHTTPRequestOperation(request: request)
        operation.responseSerializer = AFJSONResponseSerializer()
        operation.setCompletionBlockWithSuccess({(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            self.updateImageWithResponse(responseObject)
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            self.displayCurrentShowImage()
        })
        NSOperationQueue.mainQueue().addOperation(operation)
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
        let manager = AFHTTPRequestOperationManager()
        manager.requestSerializer.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData;
        manager.responseSerializer = AFImageResponseSerializer()
        let requestOperation = manager.GET(imageURL, parameters: nil, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            self.albumArtImageView.image = responseObject as? UIImage
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            self.displayCurrentShowImage()
        })
        requestOperation.start()
    }
    
    func displayCurrentShowImage() {
        let manager = AFHTTPRequestOperationManager()
        manager.requestSerializer.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData;
        manager.responseSerializer = AFImageResponseSerializer()
        let requestOperation = manager.GET(currentShow.imageURL, parameters: nil, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            self.albumArtImageView.image = responseObject as? UIImage
        }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            self.albumArtImageView.image = UIImage(contentsOfFile: "insanity-icon.png")
        })
        requestOperation.start()
    }
    
    func metaTitleUpdated(title: NSString) {
        DataModel.updateData()
        updateUI()
    }
}
