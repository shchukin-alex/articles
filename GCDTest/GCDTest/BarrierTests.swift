//
//  BarrierTests.swift
//  GCDTest
//
//  Created by Alexey Shchukin on 05.11.2021.
//

import Foundation


final class TestBarrier {
    
    let queue = DispatchQueue(label: "com.test.concurrent", attributes: .concurrent)
    
    private var internalResource: Int = 0
    var resource: Int {
        get {
            queue.sync() {
                internalResource
            }
        }
        set {
            queue.async(flags: .barrier) {
                print("--- Barrier ---")
                sleep(1) // Imitation of long work
                self.internalResource = newValue
            }
        }
    }
    
    func testBarrier() {
        for i in 0..<10 {
            if i % 2 == 0 {
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5))) {
                    self.resource = i
                }
            } else {
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5)))  {
                    print(self.resource)
                }
            }
        }
    }
}
