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
        var songProgress=self.slider.value
        audioPlayer?.seek(to: CMTime.init(seconds: Double(Float(CMTimeGetSeconds((audioPlayer?.currentItem?.duration)!))*songProgress), preferredTimescale: 1))
    }
    
    
    @IBAction func playButtonClicked(_ sender: UIButton) {
    print("playing ..........")
        let destinationURL=documentDirectoryURL.appendingPathComponent((audioURL?.lastPathComponent)!)
        musicURL=destinationURL.absoluteString
        print(musicURL)
    
        let url=URL(string:musicURL)
        var asset=AVAsset(url: url!)
        playerItem=AVPlayerItem(asset: asset)
        
        print(Float(CMTimeGetSeconds(asset.duration)))
        audioPlayer = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime , object: self.audioPlayer?.currentItem, queue: .main, using: {_ in
            print("Music Finished .... Restarting in 10 seconds..")
            sleep(10)
            self.audioPlayer?.seek(to: CMTime.init(seconds: 0, preferredTimescale: 1))
            self.audioPlayer?.play()
            
        })
        
        audioPlayer?.play()
        
        audioPlayer?.addPeriodicTimeObserver(forInterval: CMTime.init(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main, using: {time in
           var duration=self.playerItem?.duration
            var currentTime=self.playerItem?.currentTime()
            
            self.slider.value=Float(CMTimeGetSeconds(currentTime!))/Float(CMTimeGetSeconds((self.playerItem?.duration)!))
            print("\(Float(CMTimeGetSeconds(currentTime!)))    \(Float(CMTimeGetSeconds(duration!)))")
            
        })
        }
    
    
    
    
    @IBAction func stopButtonClicked(_ sender: UIButton) {
        print("Stopped clicked........")
        audioPlayer?.pause()
        
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
                var config = URLSessionConfiguration.background(withIdentifier: "mySession")
                var session=URLSession.init(configuration: config, delegate: self, delegateQueue: OperationQueue())
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
                        
                        var notificationContent=UNMutableNotificationContent()
                        notificationContent.title="Downloading your song"
                        notificationContent.body=self.musicURL
                        notificationContent.subtitle="\(self.dataDownloaded)"
                        notificationContent.userInfo=["dataDownloaded":self.dataDownloaded]
                        
                        
                        var trigger=UNTimeIntervalNotificationTrigger.init(timeInterval: 60, repeats: true)
                        
                        var notificationRequest=UNNotificationRequest.init(identifier: "myNotification", content: notificationContent, trigger: trigger)
                        
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
                
                var audioSession=AVAudioSession.sharedInstance()
                do{
                    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                    
                }
                catch{}
        })
        commandCenter.playCommand.addTarget(handler: {
            event in
            self.audioPlayer?.play()
            return MPRemoteCommandHandlerStatus.success
        })
    }

    override func didReceiveMemoryWarning() {
        print("-- memory warning --");
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    //tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        do{
            let mediaDirectory=FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            print("after music directory")
            let files = try FileManager.default.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil)
            print("after files")
            print(files.count)
            if files !=  nil{
                for i in files{
                    if i.absoluteString.hasSuffix("mp3"){
                        print(i.lastPathComponent)
                        self.songs.append(contentsOf: [i.lastPathComponent])
                        print("Song list:-------\(self.songs.count)")
                        
                    }
                }
                
                
            }
            
        }
        catch{
            print(error.localizedDescription)
        }    }

    
}

