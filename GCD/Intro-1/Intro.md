
Today I would like to start a series of articles about Grand Central Dispatch (GCD). GCD or libdispatch is one the most popular instruments for multithreading programming in iOS and MacOS. It's a library written in C to ease thread management. Instead of manual creation of threads and their subsequent control, we can use abstract queues and put all the responsibility of thread management on them.
In the series, we will cover basic primitives like queues and how to work with them, research dispatch source, and touch on DispatchIO (which is not a super popular tool). We will try to implement some basic approaches that we can use in the real world applications. And for the most curious, we will try to implement GCD primitives ourselves.

# Dispatch queues
In this first article, I'll explain dispatch queues and how to work with them. Basically queue based on the same principles as FIFO queue (one of the classical data structure primiteves). Let's make a short look what does the FIFO means. FIFO (First In First Out) is method of organizing data where the latest element (or head) in the data structure is processing first. To better understanding you can imagine line to the store in the real life. Queues manage thread pool which means they are do not overlap with the threads. There are two types of queues: serial and concurrent. In a serial queue, all the tasks execute sequentially.

FIFO Enqueue  

<img width="875" alt="Enqueue" src="https://user-images.githubusercontent.com/36634268/116985072-496b3280-accc-11eb-8eb7-78fd878a4768.png">

FIFO Dequeue 

<img width="809" alt="Dequeue" src="https://user-images.githubusercontent.com/36634268/116984681-cc3fbd80-accb-11eb-89f8-bdda55423620.png">

Here is how we can create a serial queue. As shown in Code1, A serial queue is created by default without any specification.

```swift 
// Code1
let serialQueue = DispatchQueue(label: "com.test.serialTest")
```

In contrast, a concurrent queue executes in parallel. You create the concurrent queue by setting `attributes` parameter to `concurrent`.

```swift
//Code2
let concurrentQueue = DispatchQueue(label: "com.test.concurrentTest", attributes: .concurrent)
```

The `label` parameter used in both scenarios is a unique string identifier. It helps to find the queue in different debug tools. Since GCD queues are used through different frameworks, it is recommended you choose a reverse-DNS style.

If you look at the full signature of class `DispatchQueue` init, you will notice that it has many more parameters. We we will discuss them later in the following articles. For now, it's enough to know how to create queues.


There is also a possibility to fetch a queue from a pool of queues. These queues are created by an OS and can be used for system tasks. For heavy tasks, it is better to create your own queues instead of using global ones. 

```swift
let globalQueue = DispatchQueue.global()
```

All global queues are concurrent but there is one exception in that rule - main queue. _This queue is serial and all the tasks that are queued on it are executed in the main thread_.

```swift
let mainQueue = DispatchQueue.main
```
# Async vs Sync
Let's discuss how to use queues. Async and sync are two basic methods which we can use to interact with queues. Sync waits until the task will finish and async in other hand return control of execution after it starts the task. Here in the example you can see how async and sync will work for different types of queues.

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

# Method asyncAfter

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

Ok we learned what are the basic primitives (the queues) in GCD and how to use them. It's very important to understand these concepts because all the GCD functionality based on it. It was the first part in series of articles and in the next article we will look on QOS(quality of service). I'll try to explain how it works and we will run some examples.
