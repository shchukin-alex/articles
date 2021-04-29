
Hello everyone my name is Alex and today I would like to start series of articles about gcd. Gcd or libdispatch is one the most popular instruments for multithreading programming in iOS and MacOS. Actually It's a library which was written in C to ease thread management. Indeed instead of manual creation of threads and their subsequent control we can use abstract queues and put on them all the responsibility of thread management.
In that series we will consider basic primitives like queues and how to work with them, will research dispatch source and even touch dispatch io (which is not super popular tool). Also we will try to implement some basic applications and approaches that we can do in real world applications. And for the most curious we will try to implement gcd primitives ourselves.

In this article I'll explain what is queues and how to work with them. The queue themselves manage thread pool that means they are not overlap with the threads. There are 2 types of queues: serial and concurrent. In serial queue all the tasks execute sequently.

<!--
More about internal structure of the queue.
--> 

Here how we can create serial queue. As you see serial will be created by default without any specification.
```swift
let serialQueue = DispatchQueue(label: "com.test.serialTest")
```

In concurrent queue they execute in parallel. To specify it you need to see attributes parameter as `concurrent`.
```swift
let concurrentQueue = DispatchQueue(label: "com.test.concurrentTest", attributes: .concurrent)
```

Label parameter which is used in both scenarios is the unique string identifier. It helps to find the queue in different debug tools. Since gcd queue are using through different frameworks there is a recommendation to choose reverse-DNS style.

Actually if you look on the full signature of the `DispatchQueue` init you will notice that it has much more parameters. We we will discuss them later in this course. For now it's enough to create the queues.


Also there is a possibility to get a queue from the pool of queues. These queues are created by the system and they can be used for the system tasks so in the case you have a heavy task better to create your own queue instead of using global queue.
```swift
let globalQueue = DispatchQueue.global()
```

All the global queues are concurrent but there is one exception in that rule - main queue. _This queue is serial and all the tasks that are queued on it are executed in the main thread_.
```swift
let mainQueue = DispatchQueue.main
```

Let's discuss how to use the queues. Async and sync are 2 basic methods which we can use to interact with queues. Sync waits until the task will finish and async in other hand return control of execution after it starts the task. Here in the example you can see how async and sync will work for different types of queues.

<img width="1072" alt="async" src="https://user-images.githubusercontent.com/36634268/116522532-95d1ff00-a8d5-11eb-8881-101c4bd1f193.png">

The serial queue:
```swift
serialQueue.async {
    print("test1")
}

serialQueue.async {
    sleep(1)
    print("test2")
}

serialQueue.sync {
    print("test3")
}

serialQueue.sync {
    print("test4")
}
```
Result:
```
test1
test2
test3
test4
```

Another thing good to mention that if you try to call sync method inside of sync method of the same **serial** queue. The task will be added to the queue and the queue will wait until the task will be finished. Inside the task another sync block will caused. But it will not be started until serial queue will finish the current task. So we are coming to situation when the tasks block each other. This situation called deadlock and we will look more on it in one of the next articles.

```swift
// Cause deadlock
serialQueue.sync {
    serialQueue.sync {
        print("test")
    }
}
```
And that's how we are coming to the another rule - don't call sync from the main queue in the main thread. The idea is pretty the same as in previous paragraph. Task called from the main queue is waiting because main queue can't finish the current task.

```swift
// Cause deadlock
DispatchQueue.main.sync {
    print("test")
}
```

<img width="1056" alt="sync" src="https://user-images.githubusercontent.com/36634268/116522783-dc275e00-a8d5-11eb-8225-2de2a50e8cce.png">

In the concurrent queue example we can only guarantee that `test3` will be printed after `test4`:
```swift
concurrentQueue.async {
    print("test1")
}

concurrentQueue.async {
    print("test2")
}

concurrentQueue.sync {
    print("test3")
}

concurrentQueue.sync {
    print("test4")
}
```
Result:
```
test2
test1
test3
test4

or

test1
test3
test2
test4

or
...
```
As you can see the order of the printing is arbitrary except that test3 will be printed before test4.

If we want to delay execution of the task we can use another method which called asyncAfter. This method return control of the execution to the calling thread and will execute the task in at a certain moment in time. For example in the example below the task will be executed in 3 seconds after it will be added to the queue.
```swift
concurrentQueue.asyncAfter(deadline: .now() + 3, execute: {
    print("test")
})
```
Result:
```
<- 3 seconds wait time ->
test
```

<img width="1218" alt="asyncAfter" src="https://user-images.githubusercontent.com/36634268/116523461-8bfccb80-a8d6-11eb-8caa-a2480a145d5f.png">

Let's consider situation when we execute long term task on serial queue. If we schedule the task in certain period of time and the long term task will not finish yet. That's what will happen: asyncAfter will wait until the long term task will finish and execute its tasks right after it.
```swift
serialQueue.async {
    
    sleep(3)
    print("finish")
}

serialQueue.asyncAfter(deadline: .now() + 1, execute: {
    print("test")
})
```
Result:

```
<- 3 seconds wait time ->
finish
test
```

Ok today we learned what are the basic primitives (the queues) in gcd and how to use them. It's very important to understand these concepts because all the gcd functionality based on it. It was the first part in series of articles (or even maybe course). In next article we will look on qos(quality of service). I'll try to explain how it works and we will run some examples. See you in the next part!
