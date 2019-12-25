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
    
    @IBOutlet var metalView: MetalView!
    
    var inputTime: CFTimeInterval?
     
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
     
        // Create a command queue.
        self.commandQueue = metalDevice.makeCommandQueue()!
     
        // Create the metal library containing the shaders
        let bundle = Bundle.main
        let url = bundle.url(forResource: "default", withExtension: "metallib")
        let library = try! metalDevice.makeLibrary(filepath: url!.path)
     
        // Create a function with a specific name.
        let function = library.makeFunction(name: "colorKernel")!
     
        // Create a compute pipeline with the above function.
        self.computePipelineState = try! metalDevice.makeComputePipelineState(function: function)
     
        // Initialize the cache to convert the pixel buffer into a Metal texture.
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
        self.device = metalDevice
     
        // Enable the current drawable texture read/write.
        self.framebufferOnly = false
     
        // Disable drawable auto-resize.
        self.autoResizeDrawable = false
     
        // Set the content mode to aspect fit.
        self.contentMode = .scaleAspectFit
     
        // Change drawing mode based on setNeedsDisplay().
        self.enableSetNeedsDisplay = true
        self.isPaused = true
     
        // Set the content scale factor to the screen scale.
        self.contentScaleFactor = UIScreen.main.scale
     
        // Set the size of the drawable.
        self.drawableSize = CGSize(width: 1920, height: 1080)
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
     
        // Converts the pixel buffer in a Metal texture.
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)
        guard let cvTexture = cvTextureOut, let inputTexture = CVMetalTextureGetTexture(cvTexture) else {
            fatalError("Failed to create metal texture")
            return
        }
     
        // Check if Core Animation provided a drawable.
        guard let drawable: CAMetalDrawable = self.currentDrawable else { return }
     
        // Create a command buffer
        let commandBuffer = commandQueue.makeCommandBuffer()
     
        // Create a compute command encoder.
        let computeCommandEncoder = commandBuffer!.makeComputeCommandEncoder()
     
        // Set the compute pipeline state for the command encoder.
        computeCommandEncoder!.setComputePipelineState(computePipelineState)
     
        // Set the input and output textures for the compute shader.
        computeCommandEncoder!.setTexture(inputTexture, index: 0)
        computeCommandEncoder!.setTexture(drawable.texture, index: 1)
     
        // Convert the time in a metal buffer.
        var time = Float(self.inputTime!)
        computeCommandEncoder!.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
     
        // Encode a threadgroup's execution of a compute function
        computeCommandEncoder!.dispatchThreadgroups(inputTexture.threadGroups(), threadsPerThreadgroup: inputTexture.threadGroupCount())
     
        // End the encoding of the command.
        computeCommandEncoder!.endEncoding()
     
        // Register the current drawable for rendering.
        commandBuffer.present(drawable)
     
        // Commit the command buffer for execution.
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
