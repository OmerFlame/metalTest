//
//  MetalView.swift
//  metalTest
//
//  Created by Omer Shamai on 9/1/20.
//

import SwiftUI
import Metal

struct MetalView: NSViewRepresentable {
    var device: MTLDevice!
    var queue: MTLCommandQueue!
    //var coder: NSCoder
    
    init() {
        device = MTLCreateSystemDefaultDevice()
        queue = device.makeCommandQueue()
    }
    
    func makeNSView(context: Context) -> MetalViewController {
        
        return MetalViewController(frame: NSRect(x: 0, y: 0, width: 600, height: 600), device: device as! MTLDevice, queue: queue)!
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
}
