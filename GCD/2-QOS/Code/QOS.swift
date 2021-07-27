// QoS

print(DispatchQueue.global().qos.qosClass)
print(DispatchQueue.global(qos: .background).qos.qosClass)

// QoS propagation

DispatchQueue.main.async {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}

let serialQueue = DispatchQueue(label: "com.test.serial")
let utilityQueue = DispatchQueue(label: "com.test.utility", qos: .utility)

// Automatic propagation
utilityQueue.async {
    serialQueue.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
    }
}

// Automatic propagation exception
DispatchQueue.main.async {
    serialQueue.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
    }
}

// Automatic propagation backwards

utilityQueue.async {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
    userInitiatedQueue.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
    }
}

// Manual QoS setup
let serialQueue = DispatchQueue(label: "com.test.serial")

serialQueue.async(qos: .utility) {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}

// Or

let utilityQueue = DispatchQueue(label: "com.test.utility", qos: .utility)

utilityQueue.async {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}

// inheritQoS

utilityQueue.async {
    let workItem = DispatchWorkItem(qos: .userInitiated, flags: .inheritQoS) {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
    }
    workItem.perform()
}

// Or

let workItem = DispatchWorkItem(qos: .userInitiated, flags: .inheritQoS) {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}
utilityQueue.async(execute: workItem)

// inheritQoS

let workItem = DispatchWorkItem(qos: .userInitiated, flags: .enforceQoS) {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}
utilityQueue.async(execute: workItem)


// Priority inversion

utilityQueue.async {
    sleep(2)
}
let workItem = DispatchWorkItem(qos: .userInitiated, flags: .enforceQoS) {
    sleep(1)
}
utilityQueue.async(execute: workItem)

// DispatchWorkItem perform

let serialQueue = DispatchQueue(label: "com.test.serialQueue")

let workItem = DispatchWorkItem {
    print("test")
}
serialQueue.async(execute: workItem)

// DispatchWorkItem notify

let item = DispatchWorkItem {
    print("test")
}

item.notify(queue: DispatchQueue.main) {
    print("finish")
}
serialQueue.async(execute: item)

// DispatchWorkItem cancel

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

// DispatchWorkItem wait

let workItem = DispatchWorkItem {
    print("test1")
    sleep(1)
}
serialQueue.async(execute: workItem)
workItem.wait()
print("test2")

// DispatchWorkItem barrier

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