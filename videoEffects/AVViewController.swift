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

class AVViewController: UIViewController {

    @IBOutlet weak var metalView: MetalView!
    @IBOutlet weak var brightnessSlider: UISlider!
    
    var player = AVPlayer()
    var showAVControls = false
    
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
    
    @objc func onBrightnessChange() {
        let value = brightnessSlider.value
        if metalView != nil {
            metalView.effect_brighness = value
        }
    }

    @objc func someAction(_ sender:UITapGestureRecognizer){
        print("view was clicked")
        showAVControls.toggle()
        if ( showAVControls == true ) {
            showControls()
        } else {
            hideControls()
        }
    }

    func showControls() {
    }
    
    func hideControls() {
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

   // override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
   //     return .portrait
   // }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setNeedsUpdateOfHomeIndicatorAutoHidden();
        
        brightnessSlider.addTarget(self, action: #selector(onBrightnessChange), for: UIControl.Event.valueChanged)
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.someAction (_:)))
        self.metalView.addGestureRecognizer(gesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let url = Bundle.main.url(forResource: "Dolce&Gabbana2019", withExtension: "mp4") else {
            print("Impossible to find the video.")
            return
        }
        
        let asset       = AVURLAsset(url: url)
        let playerItem  = AVPlayerItem(asset: asset)
        playerItem.add(playerItemVideoOutput)

        print("player item: ", playerItem.accessibilityFrame.size.width, playerItem.accessibilityFrame.size.height)

        player.replaceCurrentItem(with: playerItem)

        displayLink.isPaused = false
    
        player.play()
    }
    

    
    @objc private func readBuffer(_ sender: CADisplayLink) {
     
        var currentTime = CMTime.invalid
        let nextVSync = sender.timestamp + sender.duration
        currentTime = playerItemVideoOutput.itemTime(forHostTime: nextVSync)
     
        if playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime),
            let pixelBuffer = playerItemVideoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil)
            {
                if (metalView != nil ) {
                    self.metalView.pixelBuffer = pixelBuffer
                    self.metalView.inputTime = currentTime.seconds
                } else {
                    fatalError("metalView: nil")
                }
            }
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
     
    }
    
    
}

