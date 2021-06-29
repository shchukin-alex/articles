This is the second part in the GCD series and today we will mostly discuss QOS and DispatchWorkItem. 

# DispatchWorkItem

There is another way to add task to the queue (async and sync with the closures we already discussed in the previous article) through special class which called DispatchWorkItem. It is an abstract class around the closure. This class provides additional methods to interaction with the task. For example, sometimes it is necessary to receive notification about the task is finished. For that case we create DispatchWorkItem and than call notify method with completion handler where we execute our task. We also specify in which queue (in the example below it's main queue) the tasks will be executed. Than we call async method for the queue (we already know how to create serial or concurrent queue from the previous article) with the DispatchWorkItem as the parameter.

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

We can execute DispatchWorkItem manually using `perform` method as well:
```swift
let workItem = DispatchWorkItem {
    print("test")
}        
workItem.perform()
```

Another useful case for DispatchWorkItem is ability to cancel tasks. To cancel the task we can call cancel method for DispatchWorkItem. There is a big limitation - the cancellation will work only if the task is not started yet. That means the task was enqueued to the queue but didn't start to execute. In that case calling method cancel will remove DispatchWorkItem from the queue.

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

Another very handful method is `wait`. It blocks calling thread until work item will finish its task. Remember that's not good idea to call method `wait` on the main thread. The similar functionality we can see for `DispatchGroup` we will discuss it in the next article.

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

There are plenty of flags you can set in the init of DispatchWorkItem most of them related to QoS but there  

# QoS
In modern apps we as developers usually try to find some balance between performance and battery usage. In other hand since we are working in concurrent environment we need to prioritize some our tasks based on their importance. For example user click button and an animation should be displayed in that case we understand high prioritization of the rendering task. Or another example, we want to run some cleanup task to remove temporary file and user shouldn't know any updates about this task we can say that will low prioritized issue.
Quality of service is a single abstract parameter you can use to classify your work by its importance. There are four types of quality of service: `userInteractive`, `userInitiated`, `utility` and `background`. For the high priority task the application spend much more energy since it contributes more resources and for the low priority task it spend lower energy.

`userInteractive` - for tasks based on the user interaction like refreshing user interface or performing rendering. The main thread of the application always comes with `userInteractive` mode.

`userInitiated` - for tasks initiated by the user and required immediate result like the user clicks on the ui element and expects quick response.

`utility` - for tasks doesn't require immediate result but the user needs to be updated like downloading task with the progress bar.

`background` - for tasks that are not visible to the user like synchronizing or cleaning task.

There are two additional QoS classes `default` and `unspecified` that developers should not use directly

`default` - according Apple documentation, priority level of this QoS is between `userInitiated` and `utility`.
`unspecified` - it means the absence of the information about QoS and expects it will be propagated (we will explore in the next paragraph).

Interesting fact, for the global queue default QoS value is `default`:
```swift
class func global(qos: DispatchQoS.QoSClass = .default) -> DispatchQueue
```
But if we call it will display `unspecified` value:

```swift
print(DispatchQueue.global().qos.qosClass)
print(DispatchQueue.global(qos: .background).qos.qosClass)
```

Result:
```
unspecified
background
```

# QOS propagation

Another important thing to understand is how QoS can be propagated between queues. As I mentioned before main thread is associated with `userInteractive` value. That's means all the tasks you are executing on the main thread will take the high priority.

```swift
DispatchQueue.main.async {
    print(DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified)
}
```

Result:
```
userInteractive
```

In case whe don't specify qos directly for our queue it will acquire the qos from the calling thread. As you can see in the example below we don't specify the QoS for the serial queue and it's captured it automatically from the calling utility queue. That mechanics called automatic propagation.

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

 There is one important exception for previous rule - if we add the task to our queue from the `userInteractive` thread (or main thread) it will automatically decreased from `userInteractive` to `userInitiated`. 

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

But this rule doesn't work backwards. It means we are calling from the low priority thread the high priority task it will keep it's own high priority. In the example below the calling queue (utilityQueue) has less priority than called queue (userInitiatedQueue) so the task of the called queue will be executed in the `userInitiated` mode.

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

Ok let's consider situation when we need directly to specify QoS of the executing task. To do that we can set QoS as parameter for the async or sync methods of the serialQueue we created before. Or we can associate queue with specific QoS on it's set it as parameter on its creation.

<!-- utilityQueue.async(qos: .userInitiated) ??  -->

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

Ok now we know how to use QoS with the queues but there is more sophisticated cases with `DispatchWorkItem`. Using flags parameter on creation DispatchWorkItem we can define how QoS will be propagated to the task (or not). The first flag we consider called `inheritQoS` it means that the executed task will prefer to assign QoS from calling thread.

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

Another flag called `enforceQoS` and has the opposite functionality with the previous one. In this case the task will acquire QoS from the `DispatchWorkItem`.

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

There one important addition to this functionality. Let's say we have serial queue and its QoS is `utility` and there is already task added to the queue (since it's doesn't have any flags it also has QoS `utility`). This situation causes the Priority Inversion and GCD automatically resolves it raising QoS of low prioritized task. That's is not visible to the developer since it's causing by GCD. But ofc we need to keep it in mind developing concurrent application.

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