The topic of today's article is synchronization. It's one of the most important concepts in multithreading. And we will see how we can provide thread safety using GCD primitives.

# Semaphore
And the first primitive we will consider is `DispatchSemaphore`. I guess you've heard about mutex before. Briefly it's a construction which helps us to limit an access to the resource in the concurrent environment. Mutex provides an access to the resource for only one thread at the same time. In contrast semaphore can setup to provide a multiple access to the threads. You can variate the amount of threads which can get an access to the resource in the constructor of `DispatchSemaphore`. Basically `DispatchSemaphore` is a counter with two methods `signal` and `wait`. Method `signal` increments the counter and method `wait` decrements it. As you can see `DispatchSemaphore` has constructor with parameter `value` which initiate the internal counter. We will try to implement semaphore and other GCD primitives ourselves in one of following articles to make it more clear.

In the example below, we will initiate the semaphore with 0. Then asynchronously add our task to the global queue and block the calling thread by the `wait` method. When the task will be completed it will call the `signal` method which in other hand will unblock the calling thread blocked by `wait`. **Important**: never block the main thread  with method `wait` since all the UI tasks are executing on it.

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

Now let's implement thread-safe property using the semaphore. Actually there are more easy and efficient ways to do that but again this example will be good in the educational goals. I guess it looks familiar for those who knows how to work with the locks.

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
Since we are using the global queues, the order of calling setters is not guaranteed.
Result:
```
3
2
1
Result = 1
```
# Sync

Let's consider how we can restrict access to the data by multiple threads using the queues. This way I think is easier to read than the previous one. We use sync method on serial queue for getter and setter and if you remember the first article it schedule the tasks one by one according to the FIFO principle. Function `testQueueSynchronization` tries to simulate the real-world scenario which can happen in the app, I mean the spreading of calling threads. For the all even i'th it schedules asyncAfter with the writing call at the random point of time in the range of 1 and 5 seconds from the current moment. And for the all odd i'th we do the same but with the reading.

```swift
let queue = DispatchQueue(label: "com.test.serial")

private var internalResource: Int = 0
var resource: Int {
    get {
        queue.sync {
            print("Read \(internalResource)")
            sleep(1) // Imitation of long work
            return internalResource
        }
    }
    set {
        queue.sync {
            print("Write \(newValue)")
            sleep(1) // Imitation of long work
            internalResource = newValue
        }
    }
}

func testQueueSynchronization() {
    for i in 0..<10 {
        if i % 2 == 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5))) {
                self.resource = i
            }
        } else {
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5)))  {
                _ = self.resource
            }
        }
    }
}
```

And the output in my run was (ofc it will be different for you):
```
Write 4
Read 4
Read 4
Write 6
Read 6
Write 0
Read 0
Write 2
Read 2
Write 8
```

# Barrier

We can improve our previous solution using `barrier` flag which you can remember from the article about Quality of Service. There we discussed `barrier` flag for the the `DispatchWorkItem` and you will see that for queues it's the similar logic. Queues with the Dispatch barrier is considered as one of the most effective ways of synchronization. Indeed it blocks the resource only on the writing but not on the reading. So we can build our asynchronous application in a way to minimize blocking amount.

```swift
let queue = DispatchQueue(label: "com.test.concurrent", attributes: .concurrent)

private var internalResource: Int = 0
var resource: Int {
    get {
        queue.sync() {
            internalResource
        }
    }
    set {
        queue.async(flags: .barrier) {
            print("--- Barrier ---")
            sleep(1) // Imitation of long work
            self.internalResource = newValue
        }
    }
}

func testBarrier() {
    for i in 0..<10 {
        if i % 2 == 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5))) {
                self.resource = i
            }
        } else {
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5)))  {
                print(self.resource)
            }
        }
    }
}
```

In the example above we have the resource with a getter and setter. In the setter we use a barrier flag to block it but in the getter we use the sync method of the concurrent queue which is not blocking resource for multiple threads.

The output of the 'testBarrier' will be something like that:
```
--- Barrier ---
6
6
6
--- Barrier ---
--- Barrier ---
--- Barrier ---
4
--- Barrier ---
8
```
We can see that after the first barrier there are three reading calls happening at the same time.

That is it for today we've learned how we can use GCD constructions to provide thread safety in an application. Next time we will discuss `DispatchSource` and its usage.