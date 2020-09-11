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
    
    var gradientFunctions: [String] = ["purple_gradient", "turquoise_gradient", "yellow_gradient"]
    
    var recursiveFunctions: [String] = ["recursive"]
    
    var functions = [String: [MTLFunction]]()
        
    var computePipelineState: MTLComputePipelineState
    
    var visibleFunctionTable: MTLVisibleFunctionTable
    
    // var functionTable: MTLVisibleFunctionTable
    
    var visibleFunctionGroups: [String: [String]] = ["gradients" : ["purple_gradient", "turquoise_gradient", "yellow_gradient"],
                                                     "recursive" : ["test"]]
    
    
    var index: UInt32 = 0
    
    init(view: MTKView) {
        self.metal = Renderer.setupMetal()
        
        /*
        
        let functions: [MTLFunction] = self.visibleFunctions.map({
            guard let function = metal.library.makeFunction(name: $0) else {
                fatalError("Couldn't create the visible function \($0).")
            }
            return function
        })
 
        */
        
        // let visibleFunctions = gradientFunctions + recursiveFunctions
        // let visibleFunctions = gradientFunctions.append(contentsOf: recursiveFunctions)
        
        for (group, functions) in visibleFunctionGroups {
            self.functions[group] = Renderer.setupFunctions(library: metal.library, visibleFunctions: functions)
        }
        
        // self.functions["gradients"] = Renderer.setupFunctions(library: metal.library, visibleFunctions: visibleFunctionGroups["gradients"]!)
        // self.functions["test"] = Renderer.setupFunctions(library: metal.library, visibleFunctions: visibleFunctionGroups["test"]!)
        
        
        self.computePipelineState = Renderer.setupComputePipeline(device: metal.device, library: metal.library, kernelFunction: "visible", functionGroups: functions)
        
        self.visibleFunctionTable = Renderer.setupFunctionTable(library: metal.library, pipeline: computePipelineState, name: "gradients", group: functions)
        
        // self.functionTable = Renderer.setupFunctionTable(library: metal.library, pipeline: computePipelineState, name: "test", group: test)
        
        // Sometimes you know a throwing function or method won’t, in fact, throw an error at runtime.
        // On those occasions, you can write try! before the expression to disable error propagation.
        // self.pipeline = try! metal.device.makeComputePipelineState(descriptor: descriptor, options: [], reflection: nil)
 
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
    
    static func setupComputePipeline(device: MTLDevice, library: MTLLibrary, kernelFunction: String, groups: [String: [MTLFunction]]) -> (pipeline: MTLComputePipelineState, table: MTLVisibleFunctionTable) {
        
        guard let computeFunction = library.makeFunction(name: kernelFunction) else {
            fatalError("Couldn't create the kernel function.")
        }
        
        /*
        
        let functions: [MTLFunction] = visibleFunctions.map({
            guard let function = library.makeFunction(name: $0) else {
                fatalError("Couldn't create the visible function \($0).")
            }
            return function
        })
 
        */
        
        // let functions = groups.map { (group, function) in return function }
        
        // let test = Array(groups.values)
        // groups.values.reduce([], +)
            
        // var functions: [MTLFunction] = groups.values.reduce([], +)
        let functions: [MTLFunction] = Array(groups.values.joined())
        
        /*
        for f in groups.values {
            functions.append(contentsOf: f)
        }
         */
                        
        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = functions
        linkedFunctions.groups = groups
        
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
        
        
        // Use the compute pipeline to create the visible function table
        let vftDescriptor = MTLVisibleFunctionTableDescriptor()
        vftDescriptor.functionCount = functions.count
        
        guard let functionTable = pipeline.makeVisibleFunctionTable(descriptor: vftDescriptor) else {
            fatalError("Couldn't create the visible function table.")
        }
        
        for index in 0..<functions.count {
            let functionHandle = pipeline.functionHandle(function: functions[index])
            functionTable.setFunction(functionHandle, index: index)
        }
        
        return (pipeline, functionTable)
    }
    
    static func setupComputePipeline(device: MTLDevice, library: MTLLibrary, kernelFunction: String, functionGroups: [String: [MTLFunction]]) -> MTLComputePipelineState {
        
        guard let computeFunction = library.makeFunction(name: kernelFunction) else {
            fatalError("Couldn't create the kernel function.")
        }
        
        let functions: [MTLFunction] = Array(functionGroups.values.joined())
                        
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
    
    /*
    
    static func setupComputePipeline(device: MTLDevice, library: MTLLibrary, kernelFunction: String, visibleFunctions: [MTLFunction]) -> MTLVisibleFunctionTable {
        guard let computeFunction = library.makeFunction(name: kernelFunction) else {
            fatalError("Couldn't create the kernel function.")
        }
                        
        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = visibleFunctions
        // linkedFunctions.group
        
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
        
        
        // Use the compute pipeline to create the visible function table
        let vftDescriptor = MTLVisibleFunctionTableDescriptor()
        vftDescriptor.functionCount = visibleFunctions.count
        
        guard let functionTable = pipeline.makeVisibleFunctionTable(descriptor: vftDescriptor) else {
            fatalError("Couldn't create the visible function table.")
        }
        
        for index in 0..<visibleFunctions.count {
            let functionHandle = pipeline.functionHandle(function: visibleFunctions[index])
            functionTable.setFunction(functionHandle, index: index)
        }
        
        return functionTable
    }
 
    */
    
    static func setupFunctionTable(library: MTLLibrary, pipeline: MTLComputePipelineState, name: String, group: [String: [MTLFunction]]) -> MTLVisibleFunctionTable {
        guard let functions = group[name] else {
            fatalError("The functions could not be found.")
        }
            
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
        
        print(index)
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeEncoder.setComputePipelineState(computePipelineState)
        
        computeEncoder.setBytes(&index, length: MemoryLayout<UInt32>.stride, index: 0)
        computeEncoder.setVisibleFunctionTable(visibleFunctionTable, bufferIndex: 1)
        // computeEncoder.setVisibleFunctionTable(functionTable, bufferIndex: 2)
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
