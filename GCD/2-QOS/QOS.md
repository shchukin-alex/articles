This is the second part in the GCD series and here we will mostly discuss `QoS` and `DispatchWorkItem`. 

# DispatchWorkItem

There is a way to add a task to the queue through special class called `DispatchWorkItem` instead of direct passing the closure to `async` or `sync` methods. This class provides additional methods to interaction with the task. For example, sometimes it is necessary to receive completion notification. In that case we need to call method `notify` and pass completion block. We also need to specify in which queue (in the example below it's the main queue) the completion will be executed.

```swift
let item = DispatchWorkItem {
    print("test")
}

item.notify(queue: DispatchQueue.main) {
    print("finish")
}
serialQueue.async(execute: item)
```

Result:
```
test
finish
```

We can also execute DispatchWorkItem manually using `perform` method:
```swift
let workItem = DispatchWorkItem {
    print("test")
}        
workItem.perform()
```

Another useful case for DispatchWorkItem is ability to cancel tasks through `cancel` method in `DispatchWorkItem`. But there is a limitation: the cancellation will work only if the task have not started yet. Let's how it works in the example below:

```swift
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
```

Result:
```
test1
<- 1 second wait time ->
test2
```

Another very useful method is `wait`. It blocks calling thread until `DispatchWorkItem` finishes its task. Remember that's not a good idea to call method `wait` on the main thread. The similar functionality we can see for `DispatchGroup` we will discuss it in the next article.

```swift
let workItem = DispatchWorkItem {
    print("test1")
    sleep(1)
}
serialQueue.async(execute: workItem)
workItem.wait()
print("test2")
```

Result:
```
test1
<- 1 second wait time ->
test2
```

There are plenty of flags you can set in the init of `DispatchWorkItem` most of them related to `QoS` but one can be considered out of QoS context. It's called barrier and it's actually pretty similar to other barriers functionality we consider in these series. The key idea is that the work item is created with this parameter and added to the concurrent queue will wait until all the tasks in that queue will be finished and will block execution of others until it will not finish. For better understanding let's check how it work in the example below:

```swift
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
```

Result:
```
test1
<- 3 seconds ->
test2
<- 3 seconds ->
test3
```

# QoS
In modern apps we as developers usually try to find some balance between performance and battery usage. Since we work in concurrent environment we need to prioritize some our tasks based on their importance. For example the user clicks a button and an animation should be displayed. In that case we want the high prioritization of the rendering task. Or another example, we want to run some cleanup task of removing temporary files and the user shouldn't receive any updates from this task so we can say that is low prioritized issue.
Quality of service is a single abstract parameter you can use to classify your work by its importance. There are four types of quality of service: `userInteractive`, `userInitiated`, `utility` and `background`. For the high priority task the application spends much more energy since it consumes more resources and for the low priority task it spends lower energy.

`userInteractive` - for tasks based on the user interaction like refreshing user interface or performing rendering. The main thread of the application always comes with `userInteractive` mode.

`userInitiated` - for tasks initiated by the user and required immediate result like the user clicks on the ui element and expects quick response.

`utility` - for tasks doesn't require immediate result but the user needs to be updated like downloading task with the progress bar.

`background` - for tasks that are not visible to the user like synchronizing or cleaning task.

There are two additional QoS classes `default` and `unspecified` that developers should not use directly

`default` - according Apple documentation, priority level of this QoS is between `userInitiated` and `utility`.
`unspecified` - means the absence of the information about QoS and expects it will be propagated (we will explore in the next paragraph).

Interesting fact, for the global queue if we don't specify QoS the value should be `default`:
```swift
class func global(qos: DispatchQoS.QoSClass = .default) -> DispatchQueue
```
But in fact it has `unspecified` value:

```swift
print(DispatchQueue.global().qos.qosClass)
print(DispatchQueue.global(qos: .background).qos.qosClass)
```

Result:
```
unspecified
background
```

# QoS propagation

Another important thing to understand is how QoS can be propagated between queues. As I mentioned before main thread is associated with `userInteractive` value. That's means all the tasks you are executing on the main thread will take the highest priority.

```swift
DispatchQueue.main.async {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}
```

Result:
```
userInteractive
```

In case when we don't specify QoS directly in the queue it acquires the QoS from the calling thread. As you can see in the example below we don't specify the QoS for the serial queue and it captures it automatically from the calling utility queue. This mechanics is called automatic propagation.

```swift
let serialQueue = DispatchQueue(label: "com.test.serial")
let utilityQueue = DispatchQueue(label: "com.test.utility", qos: .utility)

utilityQueue.async {
    serialQueue.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
    }
}
```
Result:
```
utility
```

 There is one important exception for the previous rule - if we add the task to the queue from the `userInteractive` thread (or main thread) it automatically drops from `userInteractive` to `userInitiated`. 

```swift
DispatchQueue.main.async {
    serialQueue.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
    }
}
```
Result:
```
userInitiated
```

 Also this rule doesn't work backwards. It means if we call from the low priority thread the high priority task it keeps it's own high priority. In the example below the calling queue (utilityQueue) has low priority compare to the called queue (userInitiatedQueue) so the task of the called queue to be executed in `userInitiated` mode.

```swift
utilityQueue.async {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
    userInitiatedQueue.async {
        print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
    }
}
```
Result:
```
utility
userInitiated
```

Let's consider case when we need directly to specify QoS of the executing task. To do that we can set QoS as parameter for `async` or `sync` methods of the serialQueue we created before. Or we can associate the queue with specific QoS and set it as parameter on its creation.

```swift
let serialQueue = DispatchQueue(label: "com.test.serial")

serialQueue.async(qos: .utility) {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}

// Or

let utilityQueue = DispatchQueue(label: "com.test.utility", qos: .utility)

utilityQueue.async {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}
```
Result:
```
utility
```

Ok now we know how to use QoS with the queues but there are more sophisticated cases with `DispatchWorkItem`. Using the flags parameter in the init we can define how QoS will be propagated to the task (or not). The first flag we consider called `inheritQoS` it means that the executed task will prefer to assign QoS from calling thread.

```swift
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
```
Result:
```
utility
```

Another flag called `enforceQoS` and has reverse functionality with the previous one. In this case the task will acquire QoS from the `DispatchWorkItem`.

```swift
let workItem = DispatchWorkItem(qos: .userInitiated, flags: .enforceQoS) {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}
utilityQueue.async(execute: workItem)
```
Result:
```
userInitiated
```

There is one important addition to that functionality. Let's say we have serial queue and its QoS is `utility` and there is already task added to the queue (since it's doesn't have any flags it also has QoS `utility`). This situation causes the Priority Inversion and GCD automatically resolves it raising the QoS of low prioritized task. That is not visible to the developer since it's causing by GCD. But ofc we need to keep it in mind developing concurrent applications.

```swift
utilityQueue.async {
    sleep(2)
}
let workItem = DispatchWorkItem(qos: .userInitiated, flags: .enforceQoS) {
    sleep(1)
}
utilityQueue.async(execute: workItem)
```

<!--  Priority inversion with sync  -->

There are two other flags which were not discussed yet: `assignCurrentContext` and `detached` since they consider other attributes like `os_activity_t` and properties of the current IPC request. We will definitely explore them in the corresponding article.

So in this part we discussed pretty complicated moments related `QoS`. In the next article we will look on `DispatchGroup` and ways to work with it.