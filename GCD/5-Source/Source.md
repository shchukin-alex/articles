In this article we will discuss very important concepts as DispatchSource and target queue hierarchy.

# DispatchSource

`DispatchSource` is fundamental type which handle system events. It can be an event listener for different types like file system events, signals, memory warnings and etc.
I don't think we often use this construction in daily work but in some cases it's important to aware about it especially if you work with low level functionality. Further we will look through some subtypes you can find useful in your apps. 

We will start with the most known Dispatch source - `DispatchSourceTimer`. As you can guess by its name it works like a simple timer and generates periodical notifications which you can process in the event handler. Here is a simple example in the code snippet below:

```swift
let timerSource = DispatchSource.makeTimerSource()

func testTimerDispatchSource() {

    timerSource.setEventHandler {
        print("test")
    }
    timerSource.schedule(deadline: .now(), repeating: 5)
    timerSource.resume()
}
```

It prints word "test" in the console every 5 second.

Important: You should keep the reference to the data source somewhere in your code otherwise it will be deallocated and you will not be able to catch events. 

`DispatchSourceMemory` will help to handle memory issues you can encounter during the application work time. It can be useful if you want to have central place in your architecture which logging memory issues. In the example below it's shown how you can listen for the memory warnings. You can simulate memory warning in simulator using Debug -> Simulate Memory Warning.
 
```swift
let memorySource = DispatchSource.makeMemoryPressureSource(eventMask: .warning, queue: .main)

func testMemoryDispatchSource() {
    memorySource.setEventHandler {
        print("test")
    }
    memorySource.resume()
}
```

`DispatchSourceSignal` will track all the unix signal sending to the application. That can be useful if you are developing console application. In the example below we are catching the SIGSTOP signal. To emulate that one you can press Pause button and then Resume in debuger panel in Xcode.

```swift
let signalSource = DispatchSource.makeSignalSource(signal: SIGSTOP, queue: .main)

func testSignalSource() {
    signalSource.setEventHandler {
        print("test")
    }
    signalSource.resume()
}
```

Using DispatchSourceProcess we can listen other processes for receiving signals or making forks. For example you can use it to monitor other processes in non-iOS application. All the events you can find in `DispatchSource.ProcessEvent`. In the example below we will listen our process on receiving signals similar to what we did in the previous example. `ProcessInfo.processInfo.processIdentifier` returns processId of the current process.

```swift
let processSource = DispatchSource.makeProcessSource(identifier: ProcessInfo.processInfo.processIdentifier, eventMask: .signal, queue: .main)

func testProcessSource() {
    processSource.setEventHandler {
        print("test")
    }
    processSource.resume()
}
```

As you can see syntax of the event handling looks identically in all the examples and I hope it can provide you some gasp how and when you can use `DispatchSource` inside your applications.

Important: Do not forget to call method `cancel` or `suspend` after you finish using `DispatchSource`

It was a quick review of different DispatchSource subtypes and how to work with them. To find out how to work with `DispatchSourceFileSystemObject` I can recommend you to go through this article:
https://swiftrocks.com/dispatchsource-detecting-changes-in-files-and-folders-in-swift

# Target queue hierarchy

That is an important concept to understand. Let's say we have multiple queues in the app. We can redirect the execution of their tasks to one specific queue which called `target queue `. In the example below you can see 4 serial queues: 1 target queue and 3 others where the target queue specified. To check that all the tasks are executing on the same target queue we will print curren thread information. As you can see the thread is the same on all the cases. Target queue has `utility` QoS and it means that all the tasks executing on it will not have QoS less than `utility`. Indeed, we can see the queue which has `background` QoS is executing on `utility` instead. The queue which doesn't have a QoS will be executed on `userInitiated` because we are creating it from the main queue so it acquires `userInteractive` and decreases to `userInitiated` according to QoS rules. To learn more about the QoS you can here // TODO

```swift
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
```

Result:
```
utility
<NSThread: 0x600003ec6600>{number = 6, name = (null)}
userInitiated
<NSThread: 0x600003ec6600>{number = 6, name = (null)}
utility
<NSThread: 0x600003ec6600>{number = 6, name = (null)}
userInteractive
<NSThread: 0x600003ec6600>{number = 6, name = (null)}
```

All the tasks which will be enqueue to queue1, queue2 and queue3 will be executed in target queue. If we would not use the target queue we can encounter with a situation when `thread explosion` could occur because each serial queue executes the task on its own thread and that can produce massive context switching. So the target queue is preventing this scenario.

Based on that idea Apple recommends us to use one target queue per subsystem which ofc very reasonable: having a small amount of serial queues (and respectively threads) more efficient than having a lot working in parallel.

Today we learned different types of `DispatchSource` and how to work with `target queue hierarchy`. In the next part we will try to implement some of GCD primitives ourselves.