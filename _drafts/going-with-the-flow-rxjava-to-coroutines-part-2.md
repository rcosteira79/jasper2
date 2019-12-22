---
layout: post
current: post
cover: assets/images/going-with-the-flow-rxjava-to-coroutines-part-2.jpg
cover_caption:
cover_author: Ricardo Gomez Angel
cover_author_url: https://unsplash.com/@ripato
cover_source: Unsplash
cover_source_url: https://unsplash.com
navigation: True
comments: True
title: "Going with the Flow: RxJava to Coroutines - Part 2"
subtitle: "Testing and measuring the impact of refactoring the API request"
date: 2019-12-22 10:00:00
tags: [Android]
class: post-template
subclass: "post tag-android"
author: ricardo
published: true
---

In the <a href="{{ site.url }}/going-with-the-flow-rxjava-to-coroutines-part-1">previous article</a> I showed you two different implementations of an API request: one using RxJava, and the other using coroutines. In this article, I'll show you how can you test both implementations and how do they compare performance wise. As I did in the previous article, I'll assume that you are familiar with RxJava.

When it comes to testing, I'm all about the idea that **we should test behavior, not implementation details** (check [this nice article](https://medium.com/pleasework/what-is-a-unit-b833bc4f99e5) about testing by [Danny Preussler](https://twitter.com/PreusslerBerlin)). For this app, this would mean testing the use cases through the `ViewModel` and treating anything below it as a black box. Regardless, for the sake of this article, we'll test both our implementations.

### RxJava testing

The whole RxJava version consists of these four methods:

```Kotlin
override fun getUsersFromApi(): Observable<User> {
  return api.getAllUsers() // returns Maybe for semantic purposes - one possible response on each request.
    .flattenAsObservable { it } // However, we need to transform each element of the list
    .map { userMapper.mapToEntity(it) }
}

override fun getUserDetailsFromApi(username: Username): Maybe<DetailedUser> {
  return api.getUserDetails(username.value) // Username is an inline class. Handy for domain modeling!
    .map { detailedUserMapper.mapToEntity(it) }
}

private fun getUsersFromApiAsSingle(): Single<List<DetailedUser>> {
  return getUsersFromApi(NoParameters()) // NoParameters is a UseCase implementation detail
    .take(10) // Github API has a hourly call limit :D and 10 are more than enough for what we're doing
    .flatMapMaybe { getUserDetailsFromApi(it.username) } // 2nd api call with information from the 1st one
    .toList() // gather all stream events back into one Single list
}

private fun updateCache() {
  getUsersFromApiAsSingle()
    .doOnSuccess { Logger.d("Updating database") }
    .subscribeOn(Schedulers.io())
    .subscribe(
      { updateCachedUsers(it) }, //onSuccess
      { handleErrors(it) } // onError
    )
    .addTo(compositeDisposable) // Extension function
}
```

By testing all of these, the whole process gets covered: we test the streams we built and the transformations they go through by testing the first three methods, and how the application behaves when the final stream is subscribed by testing the last method.

To test the observable streams, we'll call the `test()` method on the Observables. This method returns a helper subscriber type already provided by RxJava. Another option is to force the stream to become synchronous through `blockingX` operators (where `X` can be `Get`, `First`, `Next`, among many others). We could use it here since we're not observing/subscribing on the main thread (obviously, using a blocking operator while running on the main thread is a recipe for disaster), but `test()` is both safer to use and more than enough in this case.
