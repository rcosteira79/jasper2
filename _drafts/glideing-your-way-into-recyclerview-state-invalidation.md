---
layout: post
current: post
cover: assets/images/glideing-your-way-into-recyclerview-state-invalidation.jpg
cover_caption: I have no idea what that says.
cover_author: Christian Wiediger
cover_author_url: https://unsplash.com/@christianw
cover_source: Unsplash
cover_source_url: https://unsplash.com
navigation: True
comments: True
title: "Glide'ing your way into RecyclerView state invalidation"
subtitle: "And Glide'ing your way out too!"
date: 2020-02-09 10:00:00
tags: [Android]
class: post-template
subclass: "post tag-android"
author: ricardo
published: true
---

A few days ago, I worked on a sample project for a tutorial. It was a very simple app: a list of images, where you could click any image to the it in full screen. The code was simple, well structured, did what it had to do, and did it well. There was only one problem: the `RecyclerView` responsible for showing the image list was resetting its state, i.e., its scroll position, when you came back to it after checking an image in full screen.

## A few things about RecyclerViews

Well, this can't be right... I'm doing everything I'm supposed to do in order for the `RecyclerView` to be able to retain its scroll position! Given the huge amount of code samples online explaining how to manually save and restore `RecyclerView` state, it seems that a lot of people think that this isn't supposed to happen automatically. Well, it is, and it's actually quite simple to do. You just have to make sure that:

1. The `RecyclerView` has an ID.
2. You setup the `Adapter` with all the data **before** the `RecyclerView` goes through its first layout pass.

The first one is simple: you just go to the layout and add an ID to the `RecyclerView`. By default, if a `View` doesn't have an ID, its state [won't be stored](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/android10-c2f2-release/core/java/android/view/View.java#20264). This one's actually hard to miss since you're probably using an ID to access the view in the code.

The second one is trickier. It's not only a matter of setting up the `Adapter` before the `RecyclerView`. You need to make sure that when the `RecyclerView` is about to go through that first layout pass, it already has **all the data** it needs. If the layout pass starts and the `Adapter` doesn't have the same data or is empty, the `RecyclerView`'s scroll position will get reset, as its state will be invalidated. So, for instance, if an app displaying a `RecyclerView` undergoes a config change and has to send an API request for data, it'll be next to impossible for the response to arrive in time for the layout pass, which means that the `RecyclerView`'s scrolling position will inevitably be reset to the initial position.

The solution here is simple: just cache the data. For example, if you have all the data cached in a `LiveData`, something like this will work:

```Kotlin
override fun onCreateView(
    inflater: LayoutInflater,
    container: ViewGroup?,
    savedInstanceState: Bundle?
  ): View? {
    val view = inflater.inflate(R.layout.fragment_list, container, false)

    val myAdapter = createAdapter()

    setupRecyclerView(view, myAdapter)
    observeViewModel(myAdapter)

    return view
  }

private fun setupRecyclerView(view: View, myAdapter: MyAdapter) {
  view.recyclerView.adapter = myAdapter

  // Other settings like listeners, setHasFixedSize, etc
}

private fun observeViewModel(myAdapter: MyAdapter) {
  viewModel.myLiveData.observe(viewLifecycleOwner) {
    myAdapter.submitList(it)
  }
}
```

By the time the `RecyclerView` starts getting drawn, the data is more than ready.

## Hello darkness my old friend

> "What am I missing?!"

This was the question I asked myself for three days. My `RecyclerView` had an ID, and my data was cached and ready on time, so what could be wrong?

I tried everything I could think of. Removing`setHasFixedSize(true)` from the `RecyclerView` setup, removing animations, setting things up in different lifecycle methods and in different combinations, persisting everything... I even saved and restored the state manually at one point, but was not happy at all with the result. Going through the `RecyclerView`'s code, I could see that its state was indeed being saved and correctly retrieved, but later invalidated. I hadn't felt this mad at Android for years!

As I was close to give up on fixing the bug and on my software engineering career in general, I began browsing Slack channels. In one specific channel, I found something that [Jon F Hancock](https://twitter.com/JonFHancock) said when trying to help someone else with a different `RecyclerView` problem:

> If the size of your RecyclerView depends on its children, you shouldn’t set that to true.

The "that" in the quote refers to `setHasFixedSize(true)`. But the bit that actually caught my attention was the first part: "_If the size of your RecyclerView depends on its children (...)_".

Holy crap. Could it be?

## I can see clearly now, the rain is gone

What Jon said was related to the `Recyclerview`'s size. However, it got me thinking about the size of the `RecyclerView`'s children.

So, here's the layout for the `RecyclerView` items:

```xml
<?xml version="1.0" encoding="utf-8"?>
<ImageView xmlns:android="http://schemas.android.com/apk/res/android"
  xmlns:tools="http://schemas.android.com/tools"
  android:id="@+id/image_view_image"
  android:layout_width="match_parent"
  android:layout_height="wrap_content"
  android:adjustViewBounds="true"
  android:contentDescription="@null"
  tools:src="@tools:sample/backgrounds/scenic" />
```

At a first glance, you probably won't see nothing unusual. And there isn't! However, this seemingly innocent code was masking a nasty bug.

The images that feed the `RecyclerView` come from an image API. The images are random, and **can have completely different heights**. Not only that, there's no telling how many bytes will each image occupy. By setting the `ImageView`'s height to `wrap_content`, I was forcing the `RecyclerView` to

<!-- tentativas com RecyclerView.Adapter e staggeredGridLayout -->
