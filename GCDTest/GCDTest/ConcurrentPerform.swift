//
//  ConcurrentPerform.swift
//  GCDTest
//
//  Created by Aleksei Shchukin on 2021-07-06.
//

import Foundation


final class ConcurrentPerformMeasure {

//    let parameters: [Int] = (0..<8).map { _ in Int.random(in: 35...44) }
    let parameters: [Int] = [43, 35, 40, 40, 38, 39, 37, 38]
    let concurrentQueue = DispatchQueue(label: "com.test.concurrent", attributes: .concurrent)

    func fibonacci(n: Int) -> Int {
        if n <= 1 {
            return n
        }
        return fibonacci(n: n - 1) + fibonacci(n: n - 2)
    }

    func concurrentPerformFibonacci() {
        DispatchQueue.concurrentPerform(iterations: parameters.count) { i in
            _ = fibonacci(n: parameters[i])
        }
    }

    func asyncFibonacci() {
        let group = DispatchGroup()
        for i in 0..<parameters.count {
            group.enter()
            self.concurrentQueue.async {
                _ = self.fibonacci(n: self.parameters[i])
                group.leave()
            }
        }
        group.wait()
    }

    func measure() {
        print(parameters)

        var measures = [Double]()

        print("Async")
        for _ in 0..<10 {
            let begin = CFAbsoluteTimeGetCurrent()
            asyncFibonacci()
            let duration = CFAbsoluteTimeGetCurrent() - begin
            print(duration)
            measures.append(duration)
        }
        print("Average async - \(measures.reduce(0.0, +) / Double(measures.count))")

        measures = []

//        print("Concurrent")
//        for _ in 0..<10 {
//            let begin = CFAbsoluteTimeGetCurrent()
//            concurrentPerformFibonacci()
//            let duration = CFAbsoluteTimeGetCurrent() - begin
//            print(duration)
//            measures.append(duration)
//        }
//        print("Average concurrent - \(measures.reduce(0.0, +) / Double(measures.count))")
    }
}


/*
 [36, 39, 35, 35, 40, 36, 35, 38, 37, 40, 36, 39, 40, 39, 38, 39, 37, 35, 36, 36, 39, 39, 36, 35, 39, 38, 36, 39, 40, 39, 37, 36]
 Concurrent
 3.3518279790878296
 3.25483500957489
 3.296175003051758
 3.0722649097442627
 3.222514033317566
 2.8790009021759033
 3.451662063598633
 5.533151030540466
 11.070425033569336
 10.323021054267883
 Average concurrent - 4.945487701892853

 Async
 3.637176036834717
 4.1981329917907715
 3.9208900928497314
 4.213144063949585
 3.832044005393982
 3.776208996772766
 3.830193042755127
 3.793861985206604
 3.772049903869629
 3.811164975166321
 Average async - 3.8784866094589234

 Concurrent
 3.385977029800415
 3.1161649227142334
 3.401739001274109
 3.1878209114074707
 3.072145104408264
 3.2597930431365967
 2.9462549686431885
 2.918246030807495
 4.10894501209259
 7.421194911003113
 Average concurrent - 3.6818280935287477





 Async
 3.3545339107513428
 3.1667169332504272
 3.1601550579071045
 3.174582004547119
 3.1427760124206543
 3.0943199396133423
 3.1783241033554077
 3.095072031021118
 3.0758860111236572
 3.1004639863967896
 Average async - 3.1542829990386965

 */
