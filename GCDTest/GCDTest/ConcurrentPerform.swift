//
//  ConcurrentPerform.swift
//  GCDTest
//
//  Created by Aleksei Shchukin on 2021-07-06.
//

import Foundation

func fibonachi(n: Int) -> Int {
    if n <= 1 {
        return n
    }
    return fibonachi(n: n - 1) + fibonachi(n: n - 2)
}

var parameters: [Int] = (0..<30).map { _ in Int.random(in: 40...42) }
func testConcurrentPerform() {
    var startTime = CFAbsoluteTimeGetCurrent()
    testConcurrent()
    print(CFAbsoluteTimeGetCurrent() - startTime)

    startTime = CFAbsoluteTimeGetCurrent()
    testGroup()
    print(CFAbsoluteTimeGetCurrent() - startTime)
    print("Finish")
}

func testConcurrent() {
    DispatchQueue.concurrentPerform(iterations: parameters.count) { i in
        let parameter = parameters[i]
        let result = fibonachi(n: parameter)
    }
}

func testGroup() {
    let group = DispatchGroup()
    for i in 0..<parameters.count {
        group.enter()
        DispatchQueue.global().async {
            let parameter = parameters[i]
            let result = fibonachi(n: parameter)
            group.leave()
        }
    }
    group.wait()
}
