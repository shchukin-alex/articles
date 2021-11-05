Topic of today's article is synchronization. It's one of the most important concepts in multithreading.

# Semaphore
And first primitive we will consider will be `DispatchSemaphore`. You probably heard before about mutex. Briefly it's tool which helps to limit access to the resource in concurrent environment. Mutex provides an access to the resource for only one thread. In contrast semaphore can provides an access to the multiple threads. You can variate the amount of thread that can get an access to the resource in the constructor of `DispatchSemaphore`. Basically `DispatchSemaphore` is a counter with two methods `signal` and `wait`. Method `signal` increments the counter and method `wait` decrements it. As you can see `DispatchSemaphore` has constructor with parameter `value` which initiate the internal counter. We will try to implement semaphore and other GCD primitives ourselves in one of following articles to make it more clear.

In the example below, we will initiate the semaphore with 0. Then asynchronously add our task to the global queue and block the calling thread by `wait` method. When the task will be completed it will call `signal` method which in other hand will unblock the calling thread blocked by `wait`. **Important**: never block the main thread  with method `wait` since all the UI tasks are executing on it.

```swift
let semaphore = DispatchSemaphore(value: 0)

DispatchQueue.global().async {
    
    print("test1")
    sleep(1)
    semaphore.signal()
}
semaphore.wait()
print("test2")
```
Result:
```
test1
<-- 3 seconds -->
test2
```

Now let's implement thread safe property throw the semaphore. Actually there are more easy and efficient ways to do that but again this example will be good in educational goals. It will look familiar for those who knows how to work with locks.

```swift
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
```
Since we are using global queues the order for the setters is not guaranteed.
Result:
```
3
2
1
Result = 1
```
# Sync

# Barrier

Dispatch barrier is considered as one of the most effective ways of synchronization. Indeed it blocks the resource only on the writing but does not on the reading. So we can build our asynchronous application in a way to minimize blocking amount.