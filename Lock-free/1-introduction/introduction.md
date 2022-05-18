Lock-free introduction

I want to start another series of articles about lock-free algorithms and how we can implement them using `swift atomics` framework. It's very complicated topic and with a lot of hidden stones there. it's very recommended not to use this approaches in real world applications. First of all it's very difficult to debug and to find mistake. Sometimes algorithms can behave very unpredictable. So the main rule working with lock-free algorithms don't trust your eyes. In other hand I believe it helps to understand how processor and memory work.

We will start with the basics in this article and discuss what are atomics, memory model.

Atomic operations.
Atomic operation is operation which cannot be split into parts while it's executing. So basically it can be done or not done. There are no any intermediate states for it. There are 3 types of atomic operations: read, write and read-write-modify(this we will discuss more later). All these operations are usually implemented as processor command and what is important they can be different for any types of processors. For example Intel and ARM has a different instructions for CAS command. Good thing is that high level atomics framework cover this issue and we can more focus on the algorithm implementation expecting we are using atomic operations.

For now we don't need to dig into the `swift atomics` framework syntax. But we can use `store` (for writing) and `load` (for reading) as atomic operations. The interesting thing is that for modern processors atomicity is guaranteed only for integral types like integers or pointers. But reading unaligned data is not atomic but compiler can guarantee correct alignment for integral types. Let's implement the simplest mutex using ONLY `store` and `load` for two threads. It's called Peterson's lock.

// Implementation

Sequential consistency:
And now we touching very important problem here. This lock will work only in sequential consistancy execution. It means that we expecting order of the execution to be the same as it's written. And now you will probably ask what? do you mean it can be reordered. Yes, it can be reordered, which is more important by processor and compiler. The processor considers the excuted code as it's only core and before when we had 1-processor architecture it was easy to support sequential consistency but nowadays when we have multiprocessored system it still considered it's only 1 proccessor execution.

Relaxed memory consistency:
So modern processors in terms of optimizations do reordering. They put read operation in beginning because the read from the memory is expensive operation and it needs to be reordered in the beginning. While the write / load operation is more cheap you don't need to wait while it ends. There are some rules about reordering commands you can find ...
Let's see how the code can be reordered

// Implementation

The good thing that we can protect our code from reordering. Barriers are telling the processor that the code surrounded the barriers should be reordered. This instruction called memory barrier. Sometimes memory barriers can be very heavy even heavier than usual mutexes. So we should be extra careful using them. Let's see how we can use it for our example.

That can be very difficult to find a correct place for memory barrier. Ofc we can cover with them big area of code but it will cost much for the machine performance. For swift we have simplified solution memory model which is inherited from C++ so it does locate memory barrier through code which simplify our work.

// Example

// TODO: C++ memory model types

Let's consider types of memory ordering in C++. 
- acquire 
- release
- sequential 

Complier reordering
The compiler doesn't know that we are working with the multithreading code either. It's assuming that all the operations happening in single thread. And ofc it makes many heuristic optimization and reordering. To prevent these renderings we can use barriers for compilers but there are good news here: the memory barriers describing above applies for compilers as well??? So we don't need to use compiler barriers directly but it's always good to understand how it works.

//Example
__asm__ __volatile__ ( "" ::: "memory" )