//
//  DispatchWorkItemTests.swift
//  GCDTest
//
//  Created by Aleksei Shchukin on 2021-05-07.
//

import Foundation

let serialQueue = DispatchQueue(label: "com.test.serial")
let utilityQueue = DispatchQueue(label: "com.test.utility", qos: .utility)
let userInitiatedQueue = DispatchQueue(label: "com.test.userInitiated", qos: .userInitiated)


func dispatchWorkItemTest() {
//        let workItem = DispatchWorkItem {
//            print("test1")
//            sleep(1)
//        }
//        serialQueue.async(execute: workItem)
//        workItem.wait()
//        print("test2")

    serialQueue.async {
        print("test1")
        sleep(1)
    }

    serialQueue.async {
        print("test2")
        sleep(1)
    }

    let item = DispatchWorkItem {
        print("test")
    }

    serialQueue.async(execute: item)

    item.cancel()
}

func testDispatchWorkItemBarrier() {

    let concurrentQueue = DispatchQueue(label: "com.test.concurrent", attributes: .concurrent)

    let workItem = DispatchWorkItem(flags: .barrier) {
        print("test2")
        sleep(3)
    }

    concurrentQueue.async {
        print("test1")
        sleep(3)
    }
    concurrentQueue.async(execute: workItem)
    concurrentQueue.async {
        print("test3")
    }
}
