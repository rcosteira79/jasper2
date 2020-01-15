---
layout: post
current: post
cover: assets/images/clearing-the-mess-between-rxjavas-subscribeon-and-observeon.jpg
cover_caption:
cover_author: amirali mirhashemian
cover_author_url: https://unsplash.com/@amir_v_ali
cover_source: Unsplash
cover_source_url: https://unsplash.com
navigation: True
comments: True
title: "Clearing the mess between RxJava's subscribeOn and observeOn"
subtitle: "How to synergize the strengths of both schedulers"
date: 2019-12-24 10:00:00
tags: [Android, Reactive Programming]
class: post-template
subclass: "post tag-android tag-reactive-programming"
author: ricardo
published: true
---

I've been talking about reactive programming a lot lately, due to my <a href="{{ site.url }}/my-talk-about-kotlin-flow-at-devfest-leiria-2019">recent talk about Kotlin Flow</a>. After talking with a lot of different Android developers, I came to the conclusion that even the most experienced people have some trouble understanding how to use RxJava's `observeOn` and `subscribeOn`. This is especially true when it comes to using them together.

This article aims to demystify the usage of both schedulers by going step by step through some code examples where they're used. But first, it's time to revisit the basics.

### Documentation is your friend

In my opinion, RxJava's documentation is really well written. Well enough to get you started, at least. If you check the documentation's [Scheduler section](http://reactivex.io/documentation/scheduler.html), a picture similar to the one below will catch your attention immediately:

<figure>
  <img 
    class="post-image-in-article-body" 
    src="{{site.url}}/assets/images/clearing-the-mess-between-rxjavas-subscribeon-and-observeon-2.jpg" 
    alt="Context switching between schedulers" />
  <figcaption>Context switching between schedulers.</figcaption>
</figure>

Each horizontal arrow with the little balls represent a stream, and each rectangle represents an operation on the stream above it. The downward arrows depict the events that get passed from stream to stream.
The original picture uses colors to represent the different threads. I'm also using colors here, but decided to swap the colored triangles inside the scheduling operators with colored numbers. I also added the numbers to the right of the downward arrows, and right side of the operators. The image has more information now, but it seems easier to reason about. For me, at least. Anyway, the numbers tell us in which thread the code is flowing on. But before going into that, it's best to clarify what `observeOn` and `subscribeOn` does:

- **observeOn**: Schedules the **downstream** to run on the specified thread. In other words, it only affects operations that run **after** it is called.
- **subscribeOn**: Schedules the **whole Observable, both upstream and downstream**, to run on the specified thread.

With this in mind, let's look at the image. It has four operators, three of them being thread scheduling ones. We can see an `observeOn(1)`, followed by a `subscribeOn(2)` and an `observeOn(3)`, in this order.

While `subscribeOn` is supposed to schedule the whole `Observable` to run in thread number two, something different is happening: it's running in thread number one, just like the streams and operators **above it but below the first `observeOn` scheduler**, as well as the streams and operators **below it until after the call of the next operator**.

The reason for this is actually quite simple! The truth is that **`observeOn` operators take precedence over `subscribeOn` operators**. This is why the call to `subscribeOn` is seemingly being ignored here – both `observeOn` operators are taking priority over it. Note that it does, however, schedule the stream before the first `observeOn` to run on thread number two, since there's no other scheduler affecting it (remember that `observeOn` only affects what happens after its call). Another important thing to note is that the events happening after the second `observeOn` call are running on the thread scheduled by this call, which means that **new `observeOn` calls take precedence over old ones**.

This can be surprinsingly hard to grasp, and things can get confusing when we start adding a lot of different `subscribeOn` and `observeOn` operators in our streams. Let's dig in deeper through some code examples.

### Getting our hands dirty

We'll use a simple helper function that will tell us in which thread the calling code is running:

```Kotlin
private fun whereAmIRunning(operationName: String) {
  println("I'm a $operationName on thread ${Thread.currentThread().name}")
}
```

With that out of the way, let's start with a simple one.

```Kotlin
Observable.just(whereAmIRunning("just"))
  .map { whereAmIRunning("map") }
  .observeOn(Schedulers.io())
  .subscribe { whereAmIRunning("subscriber") }
```

Both `just` and `map` run on the calling thread (the main thread, in this case). As for the subscription, it runs on a thread from the IO pool because of the `observeOn` above it. Nothing fancy here. The output is exactly what you'd expect:

```
I/System.out: I'm a just running on thread main
I/System.out: I'm a map running on thread main
I/System.out: I'm a subscriber running on thread RxCachedThreadScheduler-2
```

Now, if you used a `subscribeOn` instead of an `observeOn`, things would be a bit different, as the upstream would also be affected. So if we change the code to

```Kotlin
Observable.just(whereAmIRunning("just"))
  .map { whereAmIRunning("map") }
  .subscribeOn(Schedulers.io())
  .subscribe { whereAmIRunning("subscriber") }
```

The output is then

```
I/System.out: I'm a just running on thread main
I/System.out: I'm a map running on thread RxCachedThreadScheduler-3
I/System.out: I'm a subscriber running on thread RxCachedThreadScheduler-3
```

With both `map` and the subscription running on a thread from the IO pool. If you're wondering why `just` still ran on the calling thread, its because that's how `just` works: it always runs immediately – even before a subscription – and on the calling thread. For this reason, it's also worth noting that you shouldn't use it to convert expensive operations to `Observable`s, as RxJava's execution **is blocking by default**. In this case, for instance, it would block the main thread.

So, while trying not to get too out of scope here, let me just say that for the cases when you need the `Observable` creation to be deferred to another thread, you can use something like `fromCallable`. This `Observable` creation factory method only gets triggered whenever there's a subscription. So if we change the above code to

```Kotlin
Observable.fromCallable { whereAmIRunning("fromCallable") }
  .map { whereAmIRunning("map") }
  .subscribeOn(Schedulers.io())
  .subscribe { whereAmIRunning("subscriber") }
```

We now get the output

```
I/System.out: I'm a fromCallable on thread RxCachedThreadScheduler-1
I/System.out: I'm a map on thread RxCachedThreadScheduler-1
I/System.out: I'm a subscriber on thread RxCachedThreadScheduler-1
```

<!-- This is the most common case, at least on Android: you have some processing you want to keep out of the main thread, and then output the final result to it in order to update the UI. This code outputs the following: -->

<!-- observeOn
subscribeOn
subscribeon -> observeOn
observeOn -> subscribeOn
subscribeOn -> subscribeOn -> observeOn
observeOn -> observeOn -> subscribeOn -> observeOn -->

```

```
