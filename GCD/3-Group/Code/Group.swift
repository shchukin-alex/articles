import Foundation

let concurrentQueue = DispatchQueue(label: "com.test.concurrentQueue", attributes: .concurrent)
let group = DispatchGroup()

// Group notify

concurrentQueue.async(group: group) {
    sleep(1)
    print("test1")
}

concurrentQueue.async(group: group) {
    sleep(2)
    print("test2")
}

group.notify(queue: DispatchQueue.main) {
    print("All tasks were executed")
}

// Group enter

group.enter()
concurrentQueue.async {
    print("test1")
    group.leave()
}

group.enter()
concurrentQueue.async {
    print("test2")
    group.leave()
}

group.wait()
print("All tasks were executed")


// Concurrent perform

DispatchQueue.concurrentPerform(iterations: 100) { _ in
    // Execute part of the task
}

// Dispatch precondition

DispatchQueue.global().async {
    dispatchPrecondition(condition: .onQueue(.main))

    print("test")
}

DispatchQueue.global().async {
    dispatchPrecondition(condition: .notOnQueue(.global()))

    print("test")
}

DispatchQueue.global().async {
    dispatchPrecondition(condition: .notOnQueue(.main))

    print("test")
}

DispatchQueue.global().async {
    dispatchPrecondition(condition: .notOnQueue(.main))

    print("test")
}