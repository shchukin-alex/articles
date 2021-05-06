This is the second part in the GCD series and today we will mostly discuss QOS and DispatchWorkItem. 

# QOS

There are four types of quality of service: `userInteractive`, `userInitiated`, `utility` and `background`. 

`userInteractive` - 

`userInitiated` -

`utility` - 

`background` - 

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

Another useful case for DispatchWorkItem is ability to cancel tasks. To cancel the task we can call cancel method for DispatchWorkItem. There is a big limitation - the cancelation will work only if the task is not started yet. That means the task was enqueued to the queue but didn't start to execute. In that case calling method cancel will remove DispatchWorkItem from the queue.

```swift
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
```

Result:
```
test1
<- 1 second wait time ->
test2
```

<!-- DispatchWorkItem wait  -->