//
//  ViewController.swift
//  GCDTest
//
//  Created by Aleksei Shchukin on 2021-05-06.
//

import UIKit

class ViewController: UIViewController {

    let serialQueue = DispatchQueue(label: "com.test.serial")
    let utilityQueue = DispatchQueue(label: "com.test.utility", qos: .utility)
    let userInitiatedQueue = DispatchQueue(label: "com.test.userInitiated", qos: .userInitiated)

    override func viewDidLoad() {
        super.viewDidLoad()

//        let workItem = DispatchWorkItem(qos: .userInitiated, flags: .assignCurrentContext, block: {})
//        workItem.wait()
//
//        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

//        qosPropagation()
//        dispatchWorkItemTest()
//        testDispatchWorkItemQoSFlags()

//        preconditionTest()
//        testSemaphore()
//        testDispatchWorkItemBarrier()
//        testConcurrentPerform()
        
        TestBarrier().testBarrier()
    }

    func preconditionTest() {
        DispatchQueue.global().async {
            dispatchPrecondition(condition: .notOnQueue(.global()))

            print("test")
        }
    }



    func qosPropagation() {

//        DispatchQueue.global().async {
//            print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//        }

//        print(DispatchQueue.global(qos: .background).qos.qosClass)
//        print(DispatchQueue.global().qos.qosClass)

//        DispatchQueue.main.async {
//            self.serialQueue.async {
//                print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//            }
//        }

//        serialQueue.async {
//            print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//            DispatchQueue.main.async {
//                print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//            }
//        }

//        utilityQueue.async {
//            self.serialQueue.async {
//                print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//            }
//        }

        utilityQueue.async {
            print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
            self.userInitiatedQueue.async {
                print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
            }
        }

//        DispatchQueue.main.async(qos: .utility) {
//            print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//        }

//        userInitiatedQueue.async(qos: .utility) {
//            print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//        }

//        DispatchQueue.main.async {
//            self.serialQueue.async(qos: .utility) {
//                print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
//            }
//        }
    }

}

