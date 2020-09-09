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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        renderer = Renderer(view: metalView)
        
        metalView.delegate = renderer
        metalView.framebufferOnly = false
        metalView.device = renderer?.metal.device
        // metalView.colorPixelFormat = .rgba16Float
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    


}

