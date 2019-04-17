//
//  ViewController.swift
//  Music Player
//
//  Created by Sudhanshu Jaisani on 4/16/19.
//  Copyright © 2019 Sudhanshu Jaisani. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! UITableViewCell
        cell.textLabel?.text=songs[1]
        return cell
    }
    
  
  
    @IBOutlet weak var tableView: UITableView!
    
    
    var musicURL:String=""
    var audioPlayer:AVPlayer?
    var playerItem:AVPlayerItem?
    var songs:[String]=["a","b"]
    
    
   
    @IBAction func playButtonClicked(_ sender: UIButton) {
    print("playing ..........")
        print(musicURL)
        let url=URL(string:musicURL)
        let playerItem:AVPlayerItem=AVPlayerItem(url: url!)
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.play()
    
        }
    
    @IBAction func stopButtonClicked(_ sender: UIButton) {
        print("Stopped clicked........")
        audioPlayer?.pause()
        
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        print("Download clicked.......")
        if let audioURL=URL(string:"https://www.downloadnaija.com/dl/uploads/2018/11/Imagine_Dragons__Machine_(downloadnaija.com).mp3"){
            let documentDirectoryURL=FileManager.default.urls(for:.documentDirectory , in:.userDomainMask).first!
            let destinationURL=documentDirectoryURL.appendingPathComponent(audioURL.lastPathComponent)
            
            print(destinationURL)
            musicURL=destinationURL.absoluteString
            
            print("++++++File location is\(destinationURL)")
            
            if FileManager.default.fileExists(atPath: destinationURL.path){
                print("File Already Exists")
            }
            else{
                URLSession.shared.downloadTask(with: audioURL, completionHandler: {(location,response,error)->Void in
                    guard let location=location,error==nil else{return}
                    do{
                        try FileManager.default.moveItem(at: location, to:destinationURL)
                        print("File moved to document folder")
                    }
                    catch let error as NSError{
                        print("not working")
                        print(error.localizedDescription)
                    }
                    }
                ).resume()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Started")
        // Do any additional setup after loading the view, typically from a nib.
        MPMediaLibrary.requestAuthorization(
            {(status) in
                
                print("Permission granted")
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
                            self.tableView.beginUpdates()
                        }
                    }
                    
                    
                    }
                
                  
                }
                catch{
                    print(error.localizedDescription)
                }
                
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    //tableView.reloadData()
    }
    


}

