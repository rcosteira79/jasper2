---
layout: post
current: post
cover: assets/images/why-your-recycler-view-is-not-retaining-its-state.jpg
cover_caption: I have no idea what that says.
cover_author: Christian Wiediger
cover_author_url: https://unsplash.com/@christianw
cover_source: Unsplash
cover_source_url: https://unsplash.com
navigation: True
comments: True
title: "Why your RecyclerView is not retaining its state"
subtitle: "And how I almost lost my mind figuring it out"
date: 2020-02-09 10:00:00
tags: [Android]
class: post-template
subclass: "post tag-android"
author: ricardo
published: true
---

A few days ago, I worked on a sample project for a tutorial. It was a very simple app: a list of images, where you could click any image to the it in full screen. The code was simple, well structured, did what it had to do, and did it well. There was only one problem: the `RecyclerView` responsible for showing the image list was not retaining its state, i.e., its scroll position, when you came back to it after checking an image in full screen.

## A few things about RecyclerViews

Well, this can't be right... I'm doing everything I'm supposed to do in order for the `RecyclerView` to be able to retain its scroll position! It's actually quite simple to do. You just have to make sure that:

1. The `RecyclerView` has an ID.
2. You setup the `Adapter` with all the data **before** the `RecyclerView` goes through its first layout pass.

The first one is simple: you just go to the layout and add an ID to the `RecyclerView`. This one's hard to miss since you're probably using an ID to access the view in the code.

The second one is trickier.
