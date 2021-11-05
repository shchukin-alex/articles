//
//  GCDTestTests.swift
//  GCDTestTests
//
//  Created by Aleksei Shchukin on 2021-08-07.
//

import XCTest

class GCDTestTests: XCTestCase {

    func fibonacci(n: Int) -> Int {
        if n <= 1 {
            return n
        }
        return fibonacci(n: n - 1) + fibonacci(n: n - 2)
    }

    let parameters: [Int] = (0..<16).map { _ in Int.random(in: 30...40) }
    let concurrentQueue = DispatchQueue(label: "com.test.concurrent", attributes: .concurrent)
    let serialQueue = DispatchQueue(label: "com.test.serial")

    func concurrentPerformFibonacci() {
        DispatchQueue.concurrentPerform(iterations: parameters.count) { i in
            _ = fibonacci(n: parameters[i])
        }
    }

    func forQueueAsyncFibonacci() {
        let group = DispatchGroup()
        for i in 0..<parameters.count {
            group.enter()
            self.concurrentQueue.async {
                self.serialQueue.sync {
                    _ = self.fibonacci(n: self.parameters[i])
                }
                group.leave()
            }
        }
        group.wait()
    }

    func testPerformanceConcurrent() throws {
        measure {
            concurrentPerformFibonacci()
        }
    }

    func testPerformanceGroup() throws {
        measure {
            forQueueAsyncFibonacci()
        }
    }
}
