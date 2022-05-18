//
//  DispatchSourceTests.swift
//  GCDTest
//
//  Created by Aleksei Shchukin on 2022-02-17.
//

import Foundation

let timerSource = DispatchSource.makeTimerSource()
let signalSource = DispatchSource.makeSignalSource(signal: SIGSTOP, queue: .main)
let memorySource = DispatchSource.makeMemoryPressureSource(eventMask: .warning, queue: .main)
let processSource = DispatchSource.makeProcessSource(identifier: ProcessInfo.processInfo.processIdentifier, eventMask: .signal, queue: .main)

func testTimerDispatchSource() {

    timerSource.setEventHandler {
        print("test")
    }
    timerSource.schedule(deadline: .now(), repeating: 5)
    timerSource.resume()
}

func testMemoryDispatchSource() {
    memorySource.setEventHandler {
        print("test")
    }
    memorySource.resume()
}

func testSignalSource() {
    signalSource.setEventHandler {
        print("test")
    }
    signalSource.resume()
}

func testProcessSource() {
    processSource.setEventHandler {
        print("test")
    }
    processSource.resume()
}

let addSource = DispatchSource.makeUserDataAddSource(queue: .main)

func testAddDispatchSource() {
    addSource.setEventHandler {
        print(addSource.data)
    }
    addSource.resume()

    addSource.add(data: 10)
    addSource.add(data: 10)

    print(addSource.data)

    addSource.add(data: 1)

    print(addSource.data)

    DispatchQueue.global().asyncAfter(wallDeadline: .now() + 5) {
        print(addSource.data)
    }
}
