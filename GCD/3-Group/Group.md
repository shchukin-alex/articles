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

<!-- More complicated example for groups -->

# ConcurrentPerform

Sometimes we need to split our task into small pieces and execute them in parallel. For that kind of task Apple developers recommend us to use `concurrentPerform` method instead of calling for concurrent queue in a cycle. It's much more efficient since GCD manages the optimization of the thread usage itself and avoid *thread explosion* which can be caused by frequent usage of the concurrent queue.

```swift
DispatchQueue.concurrentPerform(iterations: 100) { _ in
    // Execute part of the task
}
```

<!-- Add more complicated example? -->

<!--Performance comparison-->

# Dispatch precondition

Another useful instrument we will consider today `dispatchPrecondition`. It has similar logic with asserts in swift. Basically it prevents execution of the task if the queue is not following certain condition. In example below we want to be sure that the code will be executed only on main queue. That can be useful if we want to with the UI.

```swift
DispatchQueue.global().async {
    dispatchPrecondition(condition: .onQueue(.main))

    print("test")
}
```

So as result you'll probably see an error similar to mine:
<!-- Error image -->

Or we don't want to use global queues for some heavy logic we have (as was mentioned before we should try to avoid using global queues because active usage of global queues can cause the thread explosion). Here how we can prevent that:

```swift
DispatchQueue.global().async {
    dispatchPrecondition(condition: .notOnQueue(.global()))

    print("test")
}
```

It will be the same error which you've seen in previous example.

There is an another parameter for dispatch precondition. For example we definitely want not to overload main queue with some calculations (you know we need to be super carefully executing tasks on the main thread).

```swift
DispatchQueue.global().async {
    dispatchPrecondition(condition: .notOnQueue(.main))

    print("test")
}
```

Result:
```
test
```