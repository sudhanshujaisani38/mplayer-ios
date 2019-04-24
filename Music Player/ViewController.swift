//
//  ViewController.swift
//  Music Player
//
//  Created by Sudhanshu Jaisani on 4/16/19.
//  Copyright © 2019 Sudhanshu Jaisani. All rights reserved.
//

import UIKit
import AVFoundation
import UserNotifications
import MediaPlayer

@available(iOS 10.0, *)
class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,URLSessionTaskDelegate,URLSessionDownloadDelegate,UNUserNotificationCenterDelegate{
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var downloadPercentageText: UITextField!
    
    var musicURL:String=""
    var audioPlayer:AVPlayer?
    var playerItem:AVPlayerItem?
    var songs:[String]=[]
    var dataDownloaded:Int=0
    let musicFileURLs:[URL]=[URL(string:"http://tegos.ru/new/mp3_full/Coldplay_feat_Beyonce_-_Hymn_For_The_Weekend.mp3")!,
                             URL(string:"https://mp3meet.com/siteuploads/files/sfd5/2119/Alan%20Walker%20-%20Darkside%20320kbps(Mp3meet.com).mp3")!,
                             URL(string:"https://mp3meet.com/siteuploads/files/sfd5/2328/Martin%20Garrix,%20Bonn%20-%20High%20On%20Life%20320kbps(Mp3meet.com).mp3")!]
    var audioURL:URL?
    let documentDirectoryURL=FileManager.default.urls(for:.documentDirectory , in:.userDomainMask).first!
    let commandCenter=MPRemoteCommandCenter.shared()
    var playerItemContext=0
    var itemIndex=0
    var items:[AVPlayerItem]=[]
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! UITableViewCell
        cell.textLabel?.text=songs[indexPath.item]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if audioPlayer == nil{
            
            for musicFile in musicFileURLs{
                audioURL=musicFile
                let destinationURL=documentDirectoryURL.appendingPathComponent((audioURL?.lastPathComponent)!)
                musicURL=destinationURL.absoluteString
//                print(musicURL)
                
                let url=URL(string:musicURL)
                let asset=AVAsset(url: url!)
                playerItem=AVPlayerItem(url: url!)
                items.append(playerItem!)
                
                
            }
            playerItem=items[0]
        }
        playerItem?.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayer.status),
            options: [.old, .new],
            context: &playerItemContext
        )
        if audioPlayer == nil{
            
            audioPlayer = AVPlayer(playerItem: playerItem)
        }
        var selectedItem=tableView.cellForRow(at: indexPath)?.textLabel?.text
       print( "Playing \(selectedItem)")
        audioPlayer?.pause()
        audioPlayer?.seek(to: CMTime.init(seconds: 0.0, preferredTimescale: 1))
        playButton.setTitle("Pause", for: UIControlState.normal)
        
        for item in items{
            var tempAsset = item.asset as? AVURLAsset
            if tempAsset?.url.lastPathComponent == selectedItem{
                itemIndex=items.index(of: item)!
                break
            }
        }
        audioPlayer?.replaceCurrentItem(with: items[itemIndex])
        audioPlayer?.play()
        
        audioPlayer?.addPeriodicTimeObserver(forInterval: CMTime.init(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main, using: {time in
            let duration=self.audioPlayer?.currentItem?.duration
            let currentTime=self.audioPlayer?.currentItem?.currentTime()
            self.slider.value=Float(CMTimeGetSeconds(currentTime!))/Float(CMTimeGetSeconds((self.audioPlayer?.currentItem?.duration)!))
            print("\(Float(CMTimeGetSeconds(currentTime!)))    \(Float(CMTimeGetSeconds(duration!)))")
            
        })
        putSongsOnRepeat()
        updateAudioURL()
        self.updateControlCenter(
            title: (self.audioURL?.lastPathComponent)!
            ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
            ,playBackRate:1.0
            ,timeElapsed:0.0
        )
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        print("download finished")
        DispatchQueue.main.async {
            self.downloadPercentageText.text="100%"
        }
    
         let location=location
        do{
            print(location);
            let destinationURL=self.documentDirectoryURL.appendingPathComponent((audioURL?.lastPathComponent)!)
            try FileManager.default.moveItem(at: location, to:destinationURL)
            print("File moved to document folder")
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                print("begin called")
                
            }
          
        }
        catch let error as NSError{
            print("not working")
            print(error.localizedDescription)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
         self.dataDownloaded=Int(100*Float(totalBytesWritten)/Float(totalBytesExpectedToWrite))
        print("\(self.dataDownloaded) %")
        DispatchQueue.main.async {
            self.downloadPercentageText.text="\(self.dataDownloaded)%"
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification Recieved")
    }
   
    @IBAction func sliderDragged(_ sender: UISlider) {
        var playBackRate=0.0
        if playButton.title(for: UIControlState.normal)=="Pause"{
            playBackRate=1.0
        }
        let songProgress=self.slider.value;
        audioPlayer?.seek(to: CMTime.init(seconds: Double(Float(CMTimeGetSeconds((audioPlayer?.currentItem?.duration)!))*songProgress), preferredTimescale: 1))
        self.updateControlCenter(
            title: (self.audioURL?.lastPathComponent)!
            ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
            ,playBackRate:playBackRate
            ,timeElapsed: Double(Float(CMTimeGetSeconds((audioPlayer?.currentItem?.duration)!))*songProgress)
        )
    }
    
    
    @IBAction func playButtonClicked(_ sender: UIButton) {
        if sender.title(for: UIControlState.normal)=="Play"{
            
        print("playing ..........")
            if audioPlayer==nil{
                print("please select a track to play from playlist")
            }
            else{
        
        audioPlayer?.play()
          updateAudioURL()
            self.updateControlCenter(
                title: (self.audioURL?.lastPathComponent)!
                ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                ,playBackRate: 1.0
                ,timeElapsed: (self.audioPlayer?.currentItem?.currentTime().seconds)!)
            
      sender.setTitle("Pause", for: UIControlState.normal)
            
       
            }
        }
        else{
            print("Pause clicked........")
            audioPlayer?.pause()
            self.updateControlCenter(
                title: (self.audioURL?.lastPathComponent)!
                ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                ,playBackRate: 0.0
                ,timeElapsed:  (self.audioPlayer?.currentItem?.currentTime().seconds)!)
           // playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status))
            sender.setTitle("Play", for: UIControlState.normal)
        }
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(
                forKeyPath: keyPath,
                of: object,
                change: change,
                context: context
            )
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status:AVPlayerItemStatus
            if let statusNumber=change?[.newKey] as? NSNumber{
                status=AVPlayerItemStatus(rawValue:statusNumber.intValue)!
            }
            else{
                status = .unknown
            }
            switch status{
            case .readyToPlay:print("ready to play")
            self.updateControlCenter(
                title: (self.audioURL?.lastPathComponent)!
                ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                ,playBackRate: 1.0
                ,timeElapsed: 0.0)
            case .failed: print("failed")
            case .unknown:print("unknown")
            }
        }
    }
    
    @IBAction func stopButtonClicked(_ sender: UIButton) {
        print("Stopped clicked........")
        if playButton.title(for: UIControlState.normal)=="Pause"{
        audioPlayer?.pause()
        //playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status))
        playButton.setTitle("Play", for: UIControlState.normal)
        }
       
        audioPlayer?.seek(to: CMTime(seconds: 0.0, preferredTimescale: 1))
        self.updateControlCenter(
            title: (self.audioURL?.lastPathComponent)!
            ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
            ,playBackRate: 0.0
            ,timeElapsed:  (self.audioPlayer?.currentItem?.currentTime().seconds)!)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("-- Disappeared --");
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        print("Download clicked.......")
        for musicURL in self.musicFileURLs{
            self.audioURL=musicURL
        let destinationURL=documentDirectoryURL.appendingPathComponent((audioURL?.lastPathComponent)!)
            if FileManager.default.fileExists(atPath: destinationURL.path){
                print("File Already Exists")
            }
            else{
                print("Downloading...")
                let config = URLSessionConfiguration.background(withIdentifier: "mySession")
                let session=URLSession.init(configuration: config, delegate: self, delegateQueue: OperationQueue())
                session.downloadTask(with: audioURL!).resume()
                sleep(30)
           
               }
        }
    }
    
    @IBAction func nextButton(_ sender: Any) {
        if itemIndex<(items.count-1) {
        print("next Button Clicked")
        itemIndex+=1
        audioPlayer?.pause()
            audioPlayer?.seek(to: CMTime(seconds: 0.00, preferredTimescale: 1))
        audioPlayer?.replaceCurrentItem(with: items[itemIndex])
        updateAudioURL()
        audioPlayer?.play()
        
        self.updateControlCenter(
            title: (self.audioURL?.lastPathComponent)!
            ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
            ,playBackRate: 1.0
            ,timeElapsed: (self.audioPlayer?.currentItem?.currentTime().seconds)!)
        }
        else{
            print("Reached end of playlist...")
        }
        
    }
    
    
    @IBAction func prevButtonClicked(_ sender: Any) {
        if itemIndex>0{
        print("prev Button Clicked")
        itemIndex-=1
        audioPlayer?.pause()
            audioPlayer?.seek(to: CMTime(seconds: 0.00, preferredTimescale: 1))
        audioPlayer?.replaceCurrentItem(with: items[itemIndex])
        updateAudioURL()
        audioPlayer?.play()
        
        self.updateControlCenter(
            title: (self.audioURL?.lastPathComponent)!
            ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
            ,playBackRate: 1.0
            ,timeElapsed: (self.audioPlayer?.currentItem?.currentTime().seconds)!)
        }
        else{
            print("begining of the playList")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Started")
        // Do any additional setup after loading the view, typically from a nib.
        UNUserNotificationCenter.current().delegate=self
        MPMediaLibrary.requestAuthorization(
            {(status) in
                
                print("Permission granted")
                
                let audioSession=AVAudioSession.sharedInstance()
                do{
                    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                }
                catch{
                    print("error in didLoad")
                }
        })
    }

    override func didReceiveMemoryWarning() {
        print("-- memory warning --");
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
  self.slider.setValue(0.0, animated: false)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        commandCenter.playCommand.addTarget(handler: {
            event in
            print("Play clicked from remote")
            self.audioPlayer?.play()
            self.updateControlCenter(
                title: (self.audioURL?.lastPathComponent)!
                ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                ,playBackRate: 1.0
                ,timeElapsed: (self.audioPlayer?.currentItem?.currentTime().seconds)!)
            self.playButton.setTitle("Pause", for: UIControlState.normal)
            return MPRemoteCommandHandlerStatus.success
            
        })
        
        commandCenter.pauseCommand.addTarget(handler: {
            event in
            print("Pause clicked from remote")
            
                self.audioPlayer?.pause()
            self.updateControlCenter(
                title: (self.audioURL?.lastPathComponent)!
            ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
            ,playBackRate: 0.0
            ,timeElapsed: (self.audioPlayer?.currentItem?.currentTime().seconds)!)
            self.playButton.setTitle("Play", for: UIControlState.normal)
            return  MPRemoteCommandHandlerStatus.success
        })
        
        commandCenter.seekBackwardCommand.addTarget(handler: {
            event in
            print("progress bar seeked back")
            return MPRemoteCommandHandlerStatus.success
        })
        commandCenter.stopCommand.addTarget(handler: {
            event in
            self.audioPlayer?.pause()
            self.audioPlayer?.seek(to: CMTime.init(seconds: 0.0, preferredTimescale: 1))
            self.playButton.setTitle("Play", for: UIControlState.normal)
            self.updateControlCenter(
                title: (self.audioURL?.lastPathComponent)!
                ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                ,playBackRate: 0.0
                ,timeElapsed: 0.0)
            return MPRemoteCommandHandlerStatus.success
        })
        commandCenter.nextTrackCommand.addTarget(handler: {
            event in
            
            if self.itemIndex<(self.items.count-1) {
                print("next Button Clicked from remote")
                self.itemIndex+=1
                self.audioPlayer?.pause()
                self.audioPlayer?.seek(to: CMTime(seconds: 0.00, preferredTimescale: 1))
                self.audioPlayer?.replaceCurrentItem(with: self.items[self.itemIndex])
                self.updateAudioURL()
                self.audioPlayer?.play()
                
                self.updateControlCenter(
                    title: (self.audioURL?.lastPathComponent)!
                    ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                    ,playBackRate: 1.0
                    ,timeElapsed: 0.0)
            }
            else{
                print("Reached end of playlist...")
            }

            return MPRemoteCommandHandlerStatus.success
        })
        commandCenter.previousTrackCommand.addTarget(handler: {
            event in
            if self.itemIndex>0 {
                print("prev Button Clicked from remote")
                self.itemIndex-=1
                self.audioPlayer?.pause()
                self.audioPlayer?.seek(to: CMTime(seconds: 0.00, preferredTimescale: 1))
                self.audioPlayer?.replaceCurrentItem(with: self.items[self.itemIndex])
                self.updateAudioURL()
                self.audioPlayer?.play()
                
                self.updateControlCenter(
                    title: (self.audioURL?.lastPathComponent)!
                    ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                    ,playBackRate: 1.0
                    ,timeElapsed:0.0)
            }
            else{
                print("Reached begining of playlist...")
            }

            return MPRemoteCommandHandlerStatus.success
        })
        
        commandCenter.changePlaybackPositionCommand.addTarget(handler: {
            event in
            print("seeked from remote")
            var event2=event as? MPChangePlaybackPositionCommandEvent
            
            let duration=self.audioPlayer?.currentItem?.duration
            let currentTime=event2?.positionTime
            self.slider.value=Float(currentTime!)/Float(CMTimeGetSeconds((self.audioPlayer?.currentItem?.duration)!))
         
            var playBackRate=0.0
            if self.playButton.title(for: UIControlState.normal)=="Pause"{
                playBackRate=1.0
            }
            let songProgress=self.slider.value;
            self.self.audioPlayer?.seek(to: CMTime.init(seconds: Double(Float(CMTimeGetSeconds((self.audioPlayer?.currentItem?.duration)!))*songProgress), preferredTimescale: 1))
            self.updateControlCenter(
                title: (self.audioURL?.lastPathComponent)!
                ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                ,playBackRate:playBackRate
                ,timeElapsed: Double(Float(CMTimeGetSeconds((self.audioPlayer?.currentItem?.duration)!))*songProgress)
            )
            return MPRemoteCommandHandlerStatus.success
        })
       
    
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        do{
            let mediaDirectory=FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            print("after music directory")
            let files = try FileManager.default.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil)
            var playlistItems:[AVPlayerItem]=[]
            print(files.count)
            if files !=  nil{
                for i in files{
                    if i.absoluteString.hasSuffix("mp3"){
                        print(i.lastPathComponent)
                        self.songs.append(contentsOf: [i.lastPathComponent])
                        playlistItems+=[AVPlayerItem.init(url: i)]
                    }
                }
                
            }
        }
        catch{
            print("error in view will appear")
            print(error.localizedDescription)
        }
    }

    func updateControlCenter(title:String,duration:Double,playBackRate:Double,timeElapsed:Double){
        MPNowPlayingInfoCenter.default().nowPlayingInfo=[
            MPMediaItemPropertyTitle:title,
            MPMediaItemPropertyPlaybackDuration:duration,
            MPNowPlayingInfoPropertyPlaybackRate:playBackRate,
            MPNowPlayingInfoPropertyElapsedPlaybackTime:timeElapsed
        ]
    }
    
    func updateAudioURL(){
        var assetNameForURl=self.audioPlayer?.currentItem?.asset as? AVURLAsset
        self.audioURL=assetNameForURl?.url
    }
    func putSongsOnRepeat(){
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime , object: self.audioPlayer?.currentItem, queue: .main, using: {_ in
            if self.itemIndex < (self.musicFileURLs.count-1) {
                self.itemIndex+=1
                print("Music Finished .... playing next song:\(self.itemIndex) \(self.items.count-1)")
                self.audioPlayer?.replaceCurrentItem(with: self.items[self.itemIndex])
                self.audioPlayer?.seek(to: CMTime.init(seconds: 0, preferredTimescale: 1))
                self.audioPlayer?.play()
                self.updateAudioURL()
                
                self.updateControlCenter(
                    title: (self.audioURL?.lastPathComponent)!
                    ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                    ,playBackRate:1.0
                    ,timeElapsed: 0.0
                )
                self.putSongsOnRepeat()
            }
            else{
                print("Reached end of playlist")
            }
            
        })
    }
}

