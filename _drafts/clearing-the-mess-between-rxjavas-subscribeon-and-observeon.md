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
date: 2019-12-22 10:00:00
tags: [Android, Reactive Programming]
class: post-template
subclass: "post tag-android tag-reactive-programming"
author: ricardo
published: true
---

I've been talking about reactive programming a lot lately, due to my <a href="{{ site.url }}/my-talk-about-kotlin-flow-at-devfest-leiria-2019">recent talk about Kotlin Flow</a>. After talking with a lot of different Android developers, I came to the conclusion that even the most experienced people have some trouble understanding how to use RxJava's `observeOn` and `subscribeOn`. This is especially true when it comes to using them together.

This article aims to demystify the usage of both schedulers by going step by step through some code examples where they're used. But first, it's time to revisit the basics.

### Documentation is your friend

In my opinion, RxJava's documentation is really well written. Well enough to get you started, at least. If you check the documentation's [Scheduler section](http://reactivex.io/documentation/scheduler.html), the pretty picture below will catch your attention immediately:

<div class="post-image-in-article-body">
<figure>
  <img src="{{site.url}}/assets/images/clearing-the-mess-between-rxjavas-subscribeon-and-observeon-1.png" alt="Context switching between schedulers" />
  <figcaption>Context switching between schedulers.</figcaption>
</figure>
</div>