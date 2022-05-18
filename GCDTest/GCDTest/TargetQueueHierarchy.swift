//
//  TargetQueueHierarchy.swift
//  GCDTest
//
//  Created by Aleksei Shchukin on 2022-02-22.
//

import Foundation

let targetQueue = DispatchQueue(label: "com.test.targetQueue", qos: .utility)

let queue1 = DispatchQueue(label: "com.test.queue1", target: targetQueue)
let queue2 = DispatchQueue(label: "com.test.queue2", qos: .background, target: targetQueue)
let queue3 = DispatchQueue(label: "com.test.queue3", qos: .userInteractive, target: targetQueue)

func testTargetQueueHierarchy() {
    targetQueue.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
        print(Thread.current)
    }

    queue1.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
        print(Thread.current)
    }

    queue2.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
        print(Thread.current)
    }

    queue3.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
        print(Thread.current)
    }
}
