//
//  metalView.swift
//  videoEffects
//
//  Created by Tony Monckton on 20/09/2019.
//  Copyright © 2019 Tony Monckton. All rights reserved.
//

import Foundation
import MetalKit
import CoreVideo

class MetalView: MTKView {
    
    var inputTime: CFTimeInterval?
    var effect_brighness:Float      = 1.0
    var effect_strength:Float       = 1.0
    let videoWidth:CGFloat          = 1280
    let videoHeight:CGFloat         = 720
    var pixelBuffer: CVPixelBuffer? {
        didSet {
            setNeedsDisplay()
        }
    }
     
    private var textureCache: CVMetalTextureCache?
    private var commandQueue: MTLCommandQueue
    private var computePipelineState: MTLComputePipelineState
    
    required init(coder: NSCoder) {
     
        // Get the default metal device.
        let metalDevice = MTLCreateSystemDefaultDevice()!
     
        self.commandQueue = metalDevice.makeCommandQueue()!
     
        let bundle  = Bundle.main
        let url     = bundle.url(forResource: "default", withExtension: "metallib")
        let library = try! metalDevice.makeLibrary(filepath: url!.path)
     
        let function = library.makeFunction(name: "colorKernel")!
     
        self.computePipelineState = try! metalDevice.makeComputePipelineState(function: function)
     
        var textCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textCache) != kCVReturnSuccess {
            fatalError("Unable to allocate texture cache.")
        }
        else {
            self.textureCache = textCache
        }
     
        // Initialize super.
        super.init(coder: coder)

        // Assign the metal device to this view.
        self.device                 = metalDevice
        self.framebufferOnly        = false
        self.autoResizeDrawable     = false
        self.contentMode            = .scaleAspectFit //.scaleAspectFit
        self.enableSetNeedsDisplay  = true
        self.isPaused               = true
        self.contentScaleFactor     = UIScreen.main.nativeScale //UIScreen.main.scale

        // Set the size of the drawable.
        let scale:CGFloat = videoWidth / UIScreen.main.bounds.size.width
        self.drawableSize = CGSize(width: UIScreen.main.bounds.size.width * scale, height: UIScreen.main.bounds.size.height * scale)
        
        print("UIScreen.main.nativeScale: ", UIScreen.main.nativeScale)
        print("UIScreen.main.scale: ", UIScreen.main.scale)
        print("screen: ",UIScreen.main.bounds.size.width, ", ",UIScreen.main.bounds.size.height)
        print("screen native: ",UIScreen.main.nativeBounds.size.width, ", ",UIScreen.main.nativeBounds.size.height)
        
        print("drawableSize: ", self.drawableSize)
        print("done...")
    }
    
    override func draw(_ rect: CGRect) {
        autoreleasepool {
            if rect.width > 0 && rect.height > 0 {
                self.render(self)
            }
        }
    }
    
    private func render(_ view: MTKView) {
     
        // Check if the pixel buffer exists
        guard let pixelBuffer = self.pixelBuffer else { return }
     
        // Get width and height for the pixel buffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
     
//        print("screenSize: ", UIScreen.main.bounds.size, UIScreen.main.scale)
//        print("pixelBuffer size: ", width, height)
//        print("drawableSize: ", self.drawableSize)
        
        
        // Converts the pixel buffer in a Metal texture.
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)
        guard let cvTexture = cvTextureOut, let inputTexture = CVMetalTextureGetTexture(cvTexture) else {
            fatalError("Failed to create metal texture")
        }
     
        guard let drawable: CAMetalDrawable = self.currentDrawable else { return }
     
        let commandBuffer = commandQueue.makeCommandBuffer()
     
        let computeCommandEncoder = commandBuffer!.makeComputeCommandEncoder()
        computeCommandEncoder!.setComputePipelineState(computePipelineState)
        computeCommandEncoder!.setTexture(inputTexture, index: 0)
        computeCommandEncoder!.setTexture(drawable.texture, index: 1)
     
        var time = Float(self.inputTime!)
        var effect = Float(self.effect_brighness)
        computeCommandEncoder!.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        computeCommandEncoder!.setBytes(&effect, length: MemoryLayout<Float>.size, index: 1)
        computeCommandEncoder!.dispatchThreadgroups(inputTexture.threadGroups(), threadsPerThreadgroup: inputTexture.threadGroupCount())
        computeCommandEncoder!.endEncoding()
     
        commandBuffer!.present(drawable)
        commandBuffer!.commit()
    }
}

extension MTLTexture {
 
    func threadGroupCount() -> MTLSize {
        return MTLSizeMake(8, 8, 1)
    }
 
    func threadGroups() -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSizeMake(Int(self.width) / groupCount.width, Int(self.height) / groupCount.height, 1)
    }
}
