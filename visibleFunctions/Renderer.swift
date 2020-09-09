//
//  Renderer.swift
//  visibleFunctions
//
//  Created by Eoin Roe on 08/09/2020.
//

import Foundation
import MetalKit

final class Renderer: NSObject {
    var metal: (device: MTLDevice, queue: MTLCommandQueue, library: MTLLibrary)
    
    var pipeline: MTLComputePipelineState
    
    var functionTable: MTLVisibleFunctionTable
    
    var index: UInt32 = 0
    
    init(view: MTKView) {
        self.metal = Renderer.setupMetal()
        
        /*
        
        guard let kernelFunction = metal.library.makeFunction(name: "visible"),
              let computePipeline = try? metal.device.makeComputePipelineState(function: kernelFunction) else {
            fatalError()
        }
        
        self.pipeline = computePipeline
 
        */
        
        // Kernel function
        let computeFunction = metal.library.makeFunction(name: "visible")!
        
        // Visible functions
        let purpleGradient = metal.library.makeFunction(name: "purple_gradient")!
        let turquoiseGradient = metal.library.makeFunction(name: "turquoise_gradient")!
        
        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = [purpleGradient, turquoiseGradient]
        
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = computeFunction
        descriptor.linkedFunctions = linkedFunctions
        
        // Sometimes you know a throwing function or method won’t, in fact, throw an error at runtime.
        // On those occasions, you can write try! before the expression to disable error propagation.
        self.pipeline = try! metal.device.makeComputePipelineState(descriptor: descriptor, options: [], reflection: nil)
        
        /*
            
        do {
            self.pipeline = try metal.device.makeComputePipelineState(descriptor: descriptor, options: [], reflection: nil)
        } catch {
            print(error.localizedDescription)
        }
 
        */
        
        let vftDescriptor = MTLVisibleFunctionTableDescriptor()
        vftDescriptor.functionCount = 2
        
        self.functionTable = self.pipeline.makeVisibleFunctionTable(descriptor: vftDescriptor)!
        
        var functionHandle = self.pipeline.functionHandle(function: purpleGradient)!
        functionTable.setFunction(functionHandle, index: 0)
        
        functionHandle = self.pipeline.functionHandle(function: turquoiseGradient)!
        functionTable.setFunction(functionHandle, index: 1)
 
        super.init()
    }
}

private extension Renderer {
    /// Creates the basic *non-trasient* Metal objects needed for this project.
    /// - returns: A metal device, a metal command queue, and the default library.
    static func setupMetal() -> (device: MTLDevice, queue: MTLCommandQueue, library: MTLLibrary) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device.")
        }

        guard let queue = device.makeCommandQueue() else {
            fatalError("A Metal command queue could not be created.")
        }

        guard let library = device.makeDefaultLibrary() else {
            fatalError("The default Metal library could not be created.")
        }

        return (device, queue, library)
    }
    
    static func setupComputePipeline(device: MTLDevice, library: MTLLibrary, kernelFunction: String, visibleFunctions: [String]) -> (pipeline: MTLComputePipelineState, table: MTLVisibleFunctionTable) {
        guard let computeFunction = library.makeFunction(name: kernelFunction) else {
            fatalError("Couldn't create the kernel function.")
        }
        
        let functions: [MTLFunction] = visibleFunctions.map({
            guard let function = library.makeFunction(name: $0) else {
                fatalError("Couldn't create the visible function.")
            }
            return function
        })
                        
        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = functions
        
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = computeFunction
        descriptor.linkedFunctions = linkedFunctions
        
        guard let pipeline = try? device.makeComputePipelineState(descriptor: descriptor,
                                                                 options: [],
                                                                 reflection: nil) else {
            fatalError("Couldn't create the compute pipeline state.")
        }
        
        
        // Use the compute pipeline to create the visible function table
        let vftDescriptor = MTLVisibleFunctionTableDescriptor()
        vftDescriptor.functionCount = visibleFunctions.count
        
        guard let functionTable = pipeline.makeVisibleFunctionTable(descriptor: vftDescriptor) else {
            fatalError("Couldn't create the visible function table.")
        }
        
        for index in 0..<functions.count {
            let functionHandle = pipeline.functionHandle(function: functions[index])
            functionTable.setFunction(functionHandle, index: index)
        }
        
        return (pipeline, functionTable)
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
        guard let drawable = view.currentDrawable,
              let commandBuffer = metal.queue.makeCommandBuffer() else {
            return
        }
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeEncoder.setComputePipelineState(pipeline)
        
        computeEncoder.setBytes(&index, length: MemoryLayout<UInt32>.stride, index: 0)
        computeEncoder.setVisibleFunctionTable(functionTable, bufferIndex: 1)
        computeEncoder.setTexture(drawable.texture, index: 0)
        
        // https://developer.apple.com/documentation/metal/calculating_threadgroup_and_grid_sizes
        let w = pipeline.threadExecutionWidth
        let h = pipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        
        let threadsPerGrid = MTLSize(width: drawable.texture.width,
                                     height: drawable.texture.height,
                                     depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
