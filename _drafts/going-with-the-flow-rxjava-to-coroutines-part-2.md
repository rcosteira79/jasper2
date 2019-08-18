---
layout: post
current: post
cover: assets/images/going-with-the-flow-rxjava-to-coroutines-part-2.jpg
cover_caption:
cover_author:
cover_author_url:
cover_source:
cover_source_url:
navigation: True
comments: True
title: "Going with the Flow: RxJava to Coroutines - Part 2"
subtitle: "Testing and measuring the impact of refactoring the API request"
date: 2019-08-15 10:00:00
tags: [Android]
class: post-template
subclass: "post tag-android"
author: ricardo
published: false
---

When it comes to testing, I'm all about the idea that **we should test behavior, not implementation details** (check [this nice article](https://medium.com/pleasework/what-is-a-unit-b833bc4f99e5) about testing by [Danny Preussler](https://twitter.com/PreusslerBerlin)). For this app, this would mean testing the `ViewModel` (more specifically, the use cases) and treating anything below it as a black box. Regardless, for the sake of this article, we'll test both our implementations.
