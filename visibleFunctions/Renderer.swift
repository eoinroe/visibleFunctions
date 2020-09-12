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
    
    var functions = [String: [MTLFunction]]()
    
    var visibleFunctionGroups = [String: [String]]()
        
    var computePipelineState: MTLComputePipelineState
    
    var functionTables = [String: MTLVisibleFunctionTable]()
    
    var index: UInt32 = 0
    
    var count: Int = 0
    
    init(view: MTKView) {
        self.metal = Renderer.setupMetal()
        
        self.visibleFunctionGroups["gradients"] = ["purple_gradient", "turquoise_gradient", "yellow_gradient"]
        self.visibleFunctionGroups["recursive"] = ["test"]
        
        for (group, functions) in visibleFunctionGroups {
            self.functions[group] = Renderer.setupFunctions(library: metal.library, visibleFunctions: functions)
        }
        
        self.computePipelineState = Renderer.setupComputePipeline(device: metal.device, library: metal.library, kernelFunction: "visible", functionGroups: functions)
        
        for group in functions.keys {
            functionTables[group] = Renderer.setupFunctionTable(library: metal.library, pipeline: computePipelineState, functions: functions[group]!)
        }
 
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
    
    static func setupFunctions(library: MTLLibrary, visibleFunctions: [String]) -> [MTLFunction] {
        
        let functions: [MTLFunction] = visibleFunctions.map({
            guard let function = library.makeFunction(name: $0) else {
                fatalError("Couldn't create the visible function \($0).")
            }
            return function
        })
        
        return functions
    }
    
    static func setupComputePipeline(device: MTLDevice, library: MTLLibrary, kernelFunction: String, functionGroups: [String: [MTLFunction]]) -> MTLComputePipelineState {
        
        guard let computeFunction = library.makeFunction(name: kernelFunction) else {
            fatalError("Couldn't create the kernel function.")
        }
        
        let functions: [MTLFunction] = Array(functionGroups.values.joined())
        // var functions: [MTLFunction] = groups.values.reduce([], +)
                        
        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = functions
        linkedFunctions.groups = functionGroups
        
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = computeFunction
        descriptor.linkedFunctions = linkedFunctions
        
        // For recursion
        descriptor.maxCallStackDepth = 3
        
        guard let pipeline = try? device.makeComputePipelineState(descriptor: descriptor,
                                                                 options: [],
                                                                 reflection: nil) else {
            fatalError("Couldn't create the compute pipeline state.")
        }
        
        return pipeline
    }
    
    static func setupFunctionTable(library: MTLLibrary, pipeline: MTLComputePipelineState, functions: [MTLFunction]) -> MTLVisibleFunctionTable {
                
        // Use the compute pipeline to create the visible function table
        let vftDescriptor = MTLVisibleFunctionTableDescriptor()
        vftDescriptor.functionCount = functions.count
            
        guard let functionTable = pipeline.makeVisibleFunctionTable(descriptor: vftDescriptor) else {
            fatalError("Couldn't create the visible function table.")
        }
            
        for index in 0..<functions.count {
            print(index)
            
            let functionHandle = pipeline.functionHandle(function: functions[index])
            functionTable.setFunction(functionHandle, index: index)
        }
        
        return functionTable
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
        computeEncoder.setComputePipelineState(computePipelineState)
        
        computeEncoder.setBytes(&index, length: MemoryLayout<UInt32>.stride, index: 0)
        computeEncoder.setVisibleFunctionTable(functionTables["gradients"], bufferIndex: 1)
        computeEncoder.setVisibleFunctionTable(functionTables["recursive"], bufferIndex: 2)
        computeEncoder.setTexture(drawable.texture, index: 0)
        
        // https://developer.apple.com/documentation/metal/calculating_threadgroup_and_grid_sizes
        let w = computePipelineState.threadExecutionWidth
        let h = computePipelineState.maxTotalThreadsPerThreadgroup / w
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
