let serialQueue = DispatchQueue(label: "com.test.serial")

// DispatchWorkItem notify

let item = DispatchWorkItem {
    print("test")
}

item.notify(queue: DispatchQueue.main) {
    print("finish")
}
serialQueue.async(execute: item)

// DispatchWorkItem

serialQueue.async {
    sleep(1)
    print("test1")
}

serialQueue.async {
    sleep(1)
    print("test2")
}


let item = DispatchWorkItem {
    print("test")
}

item.cancel()