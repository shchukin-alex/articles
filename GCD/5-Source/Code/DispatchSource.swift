// Timer

let timerSource = DispatchSource.makeTimerSource()

func testTimerDispatchSource() {

    timerSource.setEventHandler {
        print("test")
    }
    timerSource.schedule(deadline: .now(), repeating: 5)
    timerSource.resume()
}

// Memory

let memorySource = DispatchSource.makeMemoryPressureSource(eventMask: .warning, queue: .main)

func testMemoryDispatchSource() {
    memorySource.setEventHandler {
        print("test")
    }
    memorySource.resume()
}

// Signal

let signalSource = DispatchSource.makeSignalSource(signal: SIGSTOP, queue: .main)

func testSignalSource() {
    signalSource.setEventHandler {
        print("test")
    }
    signalSource.resume()
}

// Process

let processSource = DispatchSource.makeProcessSource(identifier: ProcessInfo.processInfo.processIdentifier, eventMask: .signal, queue: .main)

func testProcessSource() {
    processSource.setEventHandler {
        print("test")
    }
    processSource.resume()
}

// Target Queue Hierarchy

let targetQueue = DispatchQueue(label: "com.test.targetQueue", qos: .utility)

let queue1 = DispatchQueue(label: "com.test.queue1", target: targetQueue)
let queue2 = DispatchQueue(label: "com.test.queue2", qos: .background, target: targetQueue)
let queue3 = DispatchQueue(label: "com.test.queue3", qos: .userInteractive, target: targetQueue)

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