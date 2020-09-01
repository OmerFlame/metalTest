//
//  MetalNSView.swift
//  metalTest
//
//  Created by Omer Shamai on 9/1/20.
//

import Cocoa
import Metal

extension MetalViewController {
    private struct Vertex {
        var position: SIMD4<Float>
        var color: SIMD4<Float>
    }
}

/// `NSView` handling the first basic metal commands.
final class MetalViewController: NSView {
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let vertexBuffer: MTLBuffer
    private let renderPipeline: MTLRenderPipelineState
    
    init?(frame: NSRect, device: MTLDevice, queue: MTLCommandQueue) {
        // Setup the Device and Command Queue (non-transient objects: expensive to create. Do save it)
        (self.device, self.queue) = (device, queue)
        self.queue.label = "com.cracksoftware.metalTest" + ".queue"
        
        // Setup shader library
        guard let library = device.makeDefaultLibrary(),
            let vertexFunc = library.makeFunction(name: "main_vertex"),
            let fragmentFunc = library.makeFunction(name: "main_fragment") else { return nil }
        
        // Setup pipeline (non-transient)
        let pipelineDescriptor = MTLRenderPipelineDescriptor().set {
            $0.vertexFunction = vertexFunc
            $0.fragmentFunction = fragmentFunc
            $0.colorAttachments[0].pixelFormat = .bgra8Unorm   // 8-bit unsigned integer [0, 255]
        }
        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) else { return nil }
        self.renderPipeline = pipelineState
        
        // Setup buffer (non-transient). Coordinates defined in clip space: [-1,+1]
        let vertices = [Vertex(position: [-1.0, 1.0, 0, 1], color: [1,0,0,1]),
                        Vertex(position: [-1.0, -1.0, 0,1], color: [0,1,0,1]),
                        Vertex(position: [1.0, -1.0, 0, 1], color: [0,0,1,1]),
                        Vertex(position: [1.0, 1.0, 0,  1], color: [1,0,0,1]),
                        Vertex(position: [-1.0,1.0,0.0, 1], color: [0,1,0,1]),
                        Vertex(position: [1.0, -1.0, 0, 1], color: [0,0,1,1])]
        let size = vertices.count * MemoryLayout<Vertex>.stride
        guard let buffer = device.makeBuffer(bytes: vertices, length: size, options: .cpuCacheModeWriteCombined) else { return nil }
        self.vertexBuffer = buffer.set { $0.label = "com.cracksoftware.metalTest" + ".buffer" }
        
        super.init(frame: frame)
        
        // Setup layer (backing layer)
        self.wantsLayer = true
        self.metalLayer.setUp { (layer) in
            layer.device = device
            layer.pixelFormat = .bgra8Unorm
            layer.framebufferOnly = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    private var metalLayer: CAMetalLayer { self.layer as! CAMetalLayer }
    override func makeBackingLayer() -> CALayer { CAMetalLayer() }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        guard let window = self.window else { return }
        self.metalLayer.contentsScale = window.backingScaleFactor
        self.redraw()
    }
    
    override func setBoundsSize(_ newSize: NSSize) {
        super.setBoundsSize(newSize)
        self.metalLayer.drawableSize = convertToBacking(bounds).size
        self.redraw()
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        self.metalLayer.drawableSize = convertToBacking(bounds).size
        self.redraw()
    }
}

extension MetalViewController {
    /// Draws a triangle in the metal layer drawable.
    private func redraw() {
        // Setup Command Buffer (transient)
        guard let drawable = self.metalLayer.nextDrawable(),
              let commandBuffer = self.queue.makeCommandBuffer() else { return }
        
        let renderPass = MTLRenderPassDescriptor().set {
            $0.colorAttachments[0].setUp { (attachment) in
                attachment.texture = drawable.texture
                attachment.clearColor = MTLClearColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
                attachment.loadAction = .clear
                attachment.storeAction = .store
            }
        }
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else { return }
        encoder.setRenderPipelineState(self.renderPipeline)
        encoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
        
        // Present drawable is a convenience completion block that will get executed once your command buffer finishes, and will output the final texture to screen.
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

