Today we will consider one of the most useful GCD components DispatchGroup and also we will take a look on `concurrentPerform` method and dispatch precondition.

# DispatchGroup

In some cases we need to follow a certain order of our tasks. To solve these issues we can use `DispatchGroup`. As you remember in previous article we learned how to use `DispatchWorkItem`. Some of the mechanics we used there are kind of similar to `DispatchGroup`. In the example below, `DispatchGroup` created and passed as parameter to the method `async` of concurrent queue. When all the tasks in the group are completed the `notify` method will be called.

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
    print("All tasks were completed")
}
```
Result:
```
test1
test2
All tasks were executed
```

Another useful methods are `enter` and `leave`. We can use them to make an order of the tasks's execution. In the example below, we block the calling thread using method `wait` until all the tasks that were added to the group through method `enter` are marked finished through method `leave`.

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

Sometimes we need to split our task into small chunks and execute them in parallel. In that case, Apple developers recommend us to use `concurrentPerform` method instead of calling method async of concurrent queue in a cycle. It's more efficient since GCD manages optimization of the thread usage itself and avoid *thread explosion* which can be caused by frequent usage of the concurrent queue.

```swift
DispatchQueue.concurrentPerform(iterations: 12) { _ in
    // Execute part of the task
}
```

Let's consider more complicated example. I want to use a heavy computed task to show the difference between `concurrentPerform` method and usual for-loop with concurrent async. For that goal I chose recursive fibonacci sequence algorithm because its complexity is exponential (2^n) and in other hand it's pretty simple. In the code snippet below you can find computation of the n'th element in fibonacci sequence:

```swift
func fibonacci(n: Int) -> Int {
    if n <= 1 {
        return n
    }
    return fibonacci(n: n - 1) + fibonacci(n: n - 2)
}
```

Here we have input values for this function - it's generated with random numbers from certain range:

```swift
// It will produce something like these: [40, 39, 38, 36, 36, 37, 40, 35]
let parameters: [Int] = (0..<8).map { _ in Int.random(in: 35...42) }
```

So we need to calculate a fibonacci n'th for each parameter from this array. We will start with `concurrentPerform` implementation:
 
```swift
func concurrentPerformFibonacci() {
    DispatchQueue.concurrentPerform(iterations: parameters.count) { i in
        _ = fibonacci(n: parameters[i])
    }
}
```

Now we need `DispatchGroup` skills  we learned in previous section:

```swift
func asyncFibonacci() {
    let group = DispatchGroup()
    for i in 0..<parameters.count {
        group.enter()
        self.concurrentQueue.async {
            _ = self.fibonacci(n: self.parameters[i])
            group.leave()
        }
    }
    group.wait()
}
```

Here we use `DispatchGroup` to wait all the tasks we added to `concurrentQueue`. As we can see the logic behind the implementation is similar to the `concurrentPerform` example. I've written simple measuring tests which can help us to analyze performance gain we can get using the `concurrentPerform` method. Results you can find below:

 - concurrentPerform implementation:
 3.385977029800415
 3.1161649227142334
 3.401739001274109
 3.1878209114074707
 3.072145104408264
 3.2597930431365967
 2.9462549686431885
 2.918246030807495
 4.10894501209259
 7.421194911003113
 Average time for concurrentPerform - 3.6818280935287477

 - dispatchGroup implementation:
 3.637176036834717
 4.1981329917907715
 3.9208900928497314
 4.213144063949585
 3.832044005393982
 3.776208996772766
 3.830193042755127
 3.793861985206604
 3.772049903869629
 3.811164975166321
 Average time for dispatchGroup - 3.8784866094589234

All the provided measurements are displayed in seconds.

So we can see that `concurrentPerform` calculations approximately faster in 20% than `DispatchGroup` ones most of the times except last couple of calculations for `concurrentPerform`. In these two cases we can see peak values as 4.1 and 7.4. Why did it happen is a good question. My guess it could be related to that fact it happened in the end of the measurement as last two examples and priority of the calculation were passed to the some system jobs. 

Results may vary depending on the system state like how it's loaded with other tasks and threads but we can see that in general concurrentPerform 15-25% faster than `DispathcGroup` implementation.

# Dispatch precondition

Another useful instrument we take a look today is `dispatchPrecondition`. It has similar logic with the asserts in swift. Basically it prevents execution of the task if the queue doesn't follow certain condition. In example below we want to be sure that the code will be executed only on main queue. That can be useful if we want to work with UI.

```swift
DispatchQueue.global().async {
    dispatchPrecondition(condition: .onQueue(.main))

    print("test")
}
```

So as result you'll probably see an error similar to mine:
`Thread 2: EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)`

Or we don't want to use global queues for some heavy logic we have (as was mentioned before we should try to avoid using global queues because active usage of global queues can cause the thread explosion). Here how we can prevent that:

```swift
DispatchQueue.global().async {
    dispatchPrecondition(condition: .notOnQueue(.global()))

    print("test")
}
```

It will be the same error which you've seen in previous example.

Here is an another example you can use on practice. For example we do not want to overload main queue with calculations (you know we need to be super careful when we execute tasks on the main queue).

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

Today we learned how to use DispatchGroup, measure concurrentPerform and discover dispatchPrecondition. Next time we will consider different ways of threads synchronization using gcd.