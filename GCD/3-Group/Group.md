Today we will consider one of the most useful GCD components DispatchGroup also we will take a look on concurrentPerform method and dispatch precondition.

# DispatchGroup

In some cases we need to follow a certain order of our tasks. To solve these issues we can use `DispatchGroup`. As you remember in previous article we learned how to use `DispatchWorkItem`. Some of the mechanics we used there is kind of similar for `DispatchGroup`. In the example below `DispatchGroup` is created and passed as parameter to the method `async` of concurrent queue. Whenever all the tasks in the group will be executed the `notify` method will be called.

```swift
let concurrentQueue = DispatchQueue(label: "com.test.concurrentQueue", attributes: .concurrent)
let group = DispatchGroup()

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
```
Result:
```
test1
test2
All tasks were executed
```

Another useful methods are `enter` and `leave`. We can use them to make an order for the execution of tasks. In the example below we will block the calling thread using method `wait` until all the tasks that were added to the group through method `enter` will be marked finished through method `leave`.

```swift
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
```
Result:
```
test1
test2
All tasks were executed
```

# ConcurrentPerform

# Dispatch precondition