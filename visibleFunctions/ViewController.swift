//
//  ViewController.swift
//  visibleFunctions
//
//  Created by Eoin Roe on 08/09/2020.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    @IBOutlet weak var metalView: MTKView!
    
    var renderer: Renderer?
    
    var keyIsDown: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        renderer = Renderer(view: metalView)
        
        metalView.delegate = renderer
        metalView.framebufferOnly = false
        metalView.device = renderer?.metal.device
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { (aEvent) -> NSEvent? in
            self.keyUp(with: aEvent)
            return aEvent
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
            self.keyDown(with: aEvent)
            return aEvent
        }
    }

    // Swift keycodes - https://gist.github.com/swillits/df648e87016772c7f7e5dbed2b345066
    override func keyDown(with event: NSEvent) {
        if keyIsDown == true {
            return
        } else {
            keyIsDown = true
        }
       
        if event.keyCode == 0x31 {
            renderer?.index += 1
            
            if let count = renderer?.functions["gradients"]?.count {
                 renderer?.index %= UInt32(count)
            }
        }
    }
        
    override func keyUp(with event: NSEvent) {
        keyIsDown = false
        
    }
}
