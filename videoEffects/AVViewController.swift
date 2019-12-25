//
//  ViewController.swift
//  videoEffects
//
//  Created by Tony Monckton on 20/09/2019.
//  Copyright © 2019 Tony Monckton. All rights reserved.
//

import UIKit
import AVFoundation
import MetalKit
import MetalPerformanceShaders
import AVKit

class ViewController: AVPlayerViewController {

    @IBOutlet weak var metalView: MetalView!

    var player = AVPlayer()
//    var avPlayerController = AVPlayerViewController()
    
    lazy var playerItemVideoOutput: AVPlayerItemVideoOutput = {
        let attributes = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        return AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
    }()
    
    lazy var displayLink: CADisplayLink = {
        let dl = CADisplayLink(target: self, selector: #selector(readBuffer(_:)))
        dl.add(to: .current, forMode: .default)
        dl.isPaused = true
        return dl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let url = Bundle.main.url(forResource: "SS2014_Backstage", withExtension: "mp4") else {
            print("Impossible to find the video.")
            return
        }
        
        // Create an av asset for the given url.
        let asset = AVURLAsset(url: url)
         
        // Create a av player item from the asset.
        let playerItem = AVPlayerItem(asset: asset)
         
        // Add the player item video output to the player item.
        playerItem.add(playerItemVideoOutput)

        
//        avPlayerController.player = player
//        avPlayerController.showsPlaybackControls = true;
        
        // Add the player item to the player.
        player.replaceCurrentItem(with: playerItem)
       
        // Resume the display link
        displayLink.isPaused = false
    
        // Start to play
        
//        avPlayerController.player?.play()
        
        
//        player.play()

    }
    
    @objc private func readBuffer(_ sender: CADisplayLink) {
     
        var currentTime = CMTime.invalid
        let nextVSync = sender.timestamp + sender.duration
        currentTime = playerItemVideoOutput.itemTime(forHostTime: nextVSync)
     
        if playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime),
            let pixelBuffer = playerItemVideoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil)
            {
                self.metalView.pixelBuffer = pixelBuffer
                self.metalView.inputTime = currentTime.seconds

            }
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
     
    }
    
    
}

