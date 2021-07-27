//
//  QoSTests.swift
//  GCDTest
//
//  Created by Aleksei Shchukin on 2021-05-07.
//

import Foundation


func testDispatchWorkItemQoSFlags() {
    let utilityQueue = DispatchQueue(label: "com.test.backgroundQueue", qos: .utility)
//
//    utilityQueue.sync {
//        let backgroundQueue = DispatchQueue(label: "com.test.utility")
//        let workItem = DispatchWorkItem(flags: .assignCurrentContext) {
//            print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//        }
//        backgroundQueue.async(execute: workItem)
//    }


//    utilityQueue.async {
//        let workItem = DispatchWorkItem(qos: .userInitiated, flags: .inheritQoS) {
//            print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//        }
//        workItem.perform()
//    }
//
//    // Or


    utilityQueue.async {
        sleep(2)
    }
    let workItem = DispatchWorkItem(qos: .userInitiated, flags: .enforceQoS) {
        sleep(1)
    }
    utilityQueue.async(execute: workItem)
}
