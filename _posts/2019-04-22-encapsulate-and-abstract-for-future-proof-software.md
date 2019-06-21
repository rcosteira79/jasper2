---
layout: post
current: post
cover:  assets/images/encapsulate-and-abstract-for-future-proof-software.jpg
cover_caption: Things change. Even if you don’t want them to.
cover_author: bennett tobias
cover_author_url: https://unsplash.com/@bwtobias
cover_source: Unsplash
cover_source_url: https://unsplash.com
navigation: True
title: Encapsulate and abstract for future proof software
date: 2019-04-22 10:00:00
tags: [Android]
class: post-template
subclass: 'post tag-android'
author: ricardo
published: True
---

Change will always affect your software. No matter the domain, the uses cases, the developers, or even the users. Change is the one constant in software development.

This is one of the first topics addressed by the authors of the renowned [Head First Design Patterns](http://shop.oreilly.com/product/9780596007126.do). They approach it as one reason for the importance of design patterns. As they say in the book:

>"No matter how well you design an application, over time an application must grow and change or it will _die_."

Along with design patterns, the authors also introduce a bundle of design principles. While the patterns are outside the scope of this article, I want to focus on the first two principles:

- **Encapsulate what varies.**
- **Program to interfaces, not implementations.**

The first principle is the basis for all design patterns, and most of them also make use of the second one. The first one dictates that if you have code that keeps changing, pull it out and isolate it. The second principle complements this through the use of interfaces.

Now, a word of caution. As [Vasiliy Zukanov](https://medium.com/@techyourchance) explained in [this comment](https://medium.com/@techyourchance/i-havent-read-head-first-design-patterns-yet-but-i-heard-that-it-s-a-worthy-book-b53f72e9b495), this “interface” does not refer to the interface construct seen in some OOP languages. Well, it can refer to it, but it has a broader meaning. Here, “interface” refers to a component’s external point of interaction. It is what other components can use to interact with the specific component. So, this “interface” can be an interface, an abstract class, a normal class or even a function. It can be anything as long as it serves as a communication point with the component. With it, we need not know the inner details of the component. It lets us **abstract** from the component’s implementation. So, whenever there’s a change, you only need to refactor the corresponding code. The outside code will never even notice it. The purpose of the principle is indeed to focus on **what** the code does, and not **how** it does it.

### A ticking time bomb: Android Libraries

The Android open source community is awesome. No matter the complexity of what you need, a library implementing it is likely to exist already. This not only makes our jobs easier but also lets us focus on the true business logic problems.

Yet, things change (I know). Libraries become obsolete. Sometimes, new versions introduce breaking changes. Requirements change, and we no longer need a library. External changes force us to change our code. We’re left with a huge codebase full of deprecated dependencies or code built around them. This is where the design principles mentioned above come in handy.

Suppose that you need to store/retrieve a Configuration object on/from disk in JSON format. You have experience with Gson from previous projects, so you use it. You defined Configuration as:

```
data class Configuration(val aNumber: Int, val somethingWithCharacters: String)
```