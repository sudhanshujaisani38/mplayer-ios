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
    
    @IBOutlet weak var downloadPercentageText: UITextField!
    
    var musicURL:String=""
    var audioPlayer:AVPlayer?
    var playerItem:AVPlayerItem?
    var songs:[String]=[]
    var dataDownloaded:Int=0
    let audioURL=URL(string:"https://www.downloadnaija.com/dl/uploads/2018/11/Imagine_Dragons__Machine_(downloadnaija.com).mp3")
    let documentDirectoryURL=FileManager.default.urls(for:.documentDirectory , in:.userDomainMask).first!
    let commandCenter=MPRemoteCommandCenter.shared()
    var avQueuePlayer:AVQueuePlayer?
    var playerItemContext=0
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! UITableViewCell
        cell.textLabel?.text=songs[indexPath.item]
        return cell
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
                self.tableView.reloadData()
            }
            //self.tableView.reloadData()
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
        
        
        let songProgress=self.slider.value;
        audioPlayer?.seek(to: CMTime.init(seconds: Double(Float(CMTimeGetSeconds((audioPlayer?.currentItem?.duration)!))*songProgress), preferredTimescale: 1))
        self.updateControlCenter(
            title: (self.audioURL?.lastPathComponent)!
            ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
            ,playBackRate: 0.0
            ,timeElapsed: Double(Float(CMTimeGetSeconds((audioPlayer?.currentItem?.duration)!))*songProgress)
        )
    }
    
    
    @IBAction func playButtonClicked(_ sender: UIButton) {
        if sender.titleLabel?.text == "Play"{
    print("playing ..........")
        let destinationURL=documentDirectoryURL.appendingPathComponent((audioURL?.lastPathComponent)!)
        musicURL=destinationURL.absoluteString
        print(musicURL)
    
        let url=URL(string:musicURL)
        let asset=AVAsset(url: url!)
        playerItem=AVPlayerItem(asset: asset)
        playerItem?.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayer.status),
            options: [.old, .new],
            context: &playerItemContext
        )
        
   
        print(Float(CMTimeGetSeconds(asset.duration)))
        audioPlayer = AVPlayer(playerItem: playerItem)
       
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime , object: self.audioPlayer?.currentItem, queue: .main, using: {_ in
            print("Music Finished .... Restarting in 10 seconds..")
            sleep(10)
            self.audioPlayer?.seek(to: CMTime.init(seconds: 0, preferredTimescale: 1))
            self.audioPlayer?.play()
            
        })
        sleep(2)
           
        audioPlayer?.play()
            self.updateControlCenter(
                title: (self.audioURL?.lastPathComponent)!
                ,duration: (self.audioPlayer?.currentItem?.duration.seconds)!
                ,playBackRate: 1.0
                ,timeElapsed: 0.0)
        sender.titleLabel?.text="Pause"
        audioPlayer?.addPeriodicTimeObserver(forInterval: CMTime.init(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main, using: {time in
           let duration=self.playerItem?.duration
            let currentTime=self.playerItem?.currentTime()
            
            self.slider.value=Float(CMTimeGetSeconds(currentTime!))/Float(CMTimeGetSeconds((self.playerItem?.duration)!))
            print("\(Float(CMTimeGetSeconds(currentTime!)))    \(Float(CMTimeGetSeconds(duration!)))")
            
        })
        }
        else{
            audioPlayer?.pause()
            sender.titleLabel?.text="Play"
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
        audioPlayer?.pause()
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
        let destinationURL=documentDirectoryURL.appendingPathComponent((audioURL?.lastPathComponent)!)
            if FileManager.default.fileExists(atPath: destinationURL.path){
                print("File Already Exists")
            }
            else{
                print("Downloading...")
                let config = URLSessionConfiguration.background(withIdentifier: "mySession")
                let session=URLSession.init(configuration: config, delegate: self, delegateQueue: OperationQueue())
//                session.downloadTask(with: audioURL, completionHandler: {(location,response,error)->Void in
//                    guard let location=location,error==nil else{return}
//                    do{
//                        print(location);
//                        try FileManager.default.moveItem(at: location, to:destinationURL)
//                        print("File moved to document folder")
//
//
//                        DispatchQueue.main.async {
//                            self.tableView.reloadData()
//                                                    }
//                        //self.tableView.reloadData()
//                    }
//                    catch let error as NSError{
//                        print("not working")
//                        print(error.localizedDescription)
//                    }
//                    }
//                ).resume()
                session.downloadTask(with: audioURL!).resume()
                if #available(iOS 10.0, *) {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert , .sound , .badge], completionHandler: {
                        (granted,error) in
                        print("can run in this device")
                        print ("2nd statement")
                        
                        let notificationContent=UNMutableNotificationContent()
                        notificationContent.title="Downloading your song"
                        notificationContent.body=self.musicURL
                        notificationContent.subtitle="\(self.dataDownloaded)"
                        notificationContent.userInfo=["dataDownloaded":self.dataDownloaded]
                        
                        
                        let trigger=UNTimeIntervalNotificationTrigger.init(timeInterval: 60, repeats: true)
                        
                        let notificationRequest=UNNotificationRequest.init(identifier: "myNotification", content: notificationContent, trigger: trigger)
                        
                        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { (error) in
                            print(error)
                        })
                    })

                
                } else {
                    print("Cannot run in this device..")
                    // Fallback on earlier versions
                }
                
            
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
                catch{}
        })
       
    }

    override func didReceiveMemoryWarning() {
        print("-- memory warning --");
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
  
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
            return  MPRemoteCommandHandlerStatus.success
        })
        
        commandCenter.seekBackwardCommand.addTarget(handler: {
            event in
            print("progress bar seeked back")
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
                avQueuePlayer=AVQueuePlayer.init(items: playlistItems)
            }
            
            
        }
        catch{
            print(error.localizedDescription)
        }    }

    func updateControlCenter(title:String,duration:Double,playBackRate:Double,timeElapsed:Double){
        MPNowPlayingInfoCenter.default().nowPlayingInfo=[
            MPMediaItemPropertyTitle:title,
            MPMediaItemPropertyPlaybackDuration:duration,
            MPNowPlayingInfoPropertyPlaybackRate:playBackRate,   MPNowPlayingInfoPropertyElapsedPlaybackTime:timeElapsed
        ]
    }
}

