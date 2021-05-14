// Semaphore

let semaphore = DispatchSemaphore(value: 0)

DispatchQueue.global().async {

    print("test1")
    sleep(1)
    semaphore.signal()
}
semaphore.wait()
print("test2")


// Semaphore synchronization

let semaphore = DispatchSemaphore(value: 1)

private var internalResource: Int = 0
var resource: Int {
    get {
        defer {
            semaphore.signal()
        }
        semaphore.wait()
        return internalResource
    }
    set {
        semaphore.wait()

        print(newValue)
        internalResource = newValue
        sleep(1)
        
        semaphore.signal()
    }
}

let group = DispatchGroup()
DispatchQueue.global().async(group: group) {
    resource = 1
}
DispatchQueue.global().async(group: group) {
    resource = 2
}
DispatchQueue.global().async(group: group) {
    resource = 3
}

group.notify(queue: .global()) {
    print("Result = \(resource)")
}