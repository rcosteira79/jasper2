---
layout: post
current: post
cover: assets/images/going-with-the-flow-rxjava-to-coroutines-part-1.jpg
cover_caption:
cover_author: Denys Nevozhai
cover_author_url: https://unsplash.com/@dnevozhai
cover_source: Unsplash
cover_source_url: https://unsplash.com
navigation: True
comments: True
title: "Going with the Flow: RxJava to Coroutines - Part 1"
subtitle: "Refactoring an API request"
date: 2019-08-15 10:00:00
tags: [Android]
class: post-template
subclass: "post tag-android"
author: ricardo
published: True
---

In the last couple of weeks, I've been playing around with Kotlin coroutines. I had some trouble wrapping my head around the whole concept, mainly because I was consistently looking out for RxJava resemblances. Well, the truth is RxJava is one thing, and coroutines are another thing. Sure, they can be used for the same use cases, but they're two different concepts. I'll try not to go too deep into the rabit hole here, but RxJava is an API for asynchronous and/or concurrent programming that follows the **functional** and **reactive** paradigms. On the other hand, the coroutines library aims to facilitate asynchronous and/or concurrent programming, while **deferring the decision of going functional or reactive to the user**. Once I became aware of this, coroutines became a lot easier to understand. This also means that they're easier to grasp for beginners, or just someone that's not familiarized with RxJava.

In this article series, I will go through a sample app built with RxJava and refactor it to use coroutines. I will show you both implementations and explain the reasoning behind them. I will measure performance (I'm an Engineer™) and show you how can you write tests for both versions. In this article, I'll start with the refactoring that, in my opinion, lays the foundation to understand the upcoming ones - the refactoring of a Retrofit-powered API request. So, let's get started.

### The app

Well, more like "The view". I didn't want to show you just small "before" and "after" code samples, but I also didn't want to make an extremely complex and hard to follow app.

<figure>
  <img src="{{site.url}}/assets/images/going-with-the-flow-rxjava-to-coroutines-part-1-1.png" alt="App screenshot"/>
  <figcaption>Design skills too stronk.</figcaption>
</figure>

The UI is composed by a Fragment with a search bar and a RecyclerView (don't mind the BottomNavigationView, it's there just so that I can jump between different code samples - this is my skeleton/playground project). Each RecyclerView item shows a card with user information. When the app starts, it checks the database for existing data, and displays it accordingly. It also queries the Github API for more data in order to update the database. The search bar filters the user list by name, and the _DELETE_ button on each card sends a delete command to the database for the corresponding user.

I'm using Room for the database and, as mentioned before, Retrofit for the Github API requests. Dependencies are provided by Dagger. The app as a whole is built using a common pattern ([Clean Architecture](http://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)). State management is managed through view state and view events classes. Data flow between the view and the ViewModel is unidirectional. If you want to know more about the implementation details, you can check the [repository](https://github.com/rcosteira79/AndroidMultiModuleCleanArchTemplate). That said, let us dive into the API request details.

### Handling an API request with RxJava

So, in order to compose that UI we need to fetch the users from the Github API. However, some of the information that we want to show just as the location or the blog url are not available in the list that the API returns. As such, we need to do another request - one for **each** user - to retrieve more details.

Given this, the app has the following Retrofit API:

```Kotlin
interface Api {
  @GET("users")
  fun getAllUsers(): Maybe<List<GithubUser>>

  @GET("users/{username}")
  fun getUserDetails(@Path("username") username: String): Maybe<GithubDetailedUser>
}
```

Yes, I could use Observable instead of Maybe here, but Maybe makes more _semantic_ meaning to me: maybe I will get the response I expect, or maybe I wont. Still, Observable is more versatile than Maybe. Not only that, but `getAllUsers` returns a `List<GithubUser>` stream, and we need to operate on each individual user. So the **repository** converts this stream into an Observable stream of `GithubUser`. The other stream remains the same (for now):

```Kotlin
override fun getUsersFromApi(): Observable<User> {
  return api.getAllUsers() // returns Maybe for semantic purposes - one possible response on each request.
    .flattenAsObservable { it } // However, transformations are easier with Observables :)
    .map { userMapper.mapToEntity(it) }
}

override fun getUserDetailsFromApi(username: Username): Maybe<DetailedUser> {
  return api.getUserDetails(username.value)
    .map { detailedUserMapper.mapToEntity(it) }
}
```

Following Clean Architecture, I have UseCase classes connecting the ViewModel to the repository. Regardless, I'm skipping them here since I'm only using them to define the boundary, i.e., they just forward the calls from the ViewModel to the repository. This is actually something that bothers me, because according to the Clean Architecture definition, a use case should contain the business logic. On Android though, we tend to keep the business logic both in the repository and the ViewModel (at least in most Clean Architecture implementations I've seen so far). In other words, the UseCase classes are practically useless, doing nothing more than defining a boundary. Maybe they don't make any sense at all, since most of the work done by an Android app is fetching data from wherever and showing it on the screen. Anyway, this is a subject for another article, maybe. Back to the refactoring.

So, the API is ready, and the repository is ready. Now we just need to make the call in the ViewModel, and subscribe to it:

```Kotlin
// Gets users from the api and stores them in the database
private fun updateCache() {
  getUsersFromApiAsSingle()
    .doOnSuccess { Logger.d("Updating database") }
    .subscribeOn(Schedulers.io())
    .subscribe(
      { updateCachedUsers(it) },
      { handleErrors(it) }
    )
    .addTo(compositeDisposable) // Extension function
}

private fun getUsersFromApiAsSingle(): Single<List<DetailedUser>> {
  return getUsersFromApi(NoParameters())
    .take(10) // Github API has a hourly call limit :D and 10 are more than enough for what we're doing
    .flatMapMaybe { getUserDetailsFromApi(it.username) } // 2nd api call with information from the 1st one
    .toList() // gather all stream events back into one list -> List<DetailedUser>
}
```

I'm gonna pretend I don't have all these layers and boundaries for a second, so that the whole process is easier to visualize:

```Kotlin
api.getAllUsers() // returns Maybe for semantic purposes - one possible response on each request.
  .flattenAsObservable { it } // However, transformations are easier with Observables :)
  .map { userMapper.mapToEntity(it) }
  .take(10) // Github API has a hourly call limit :D and 10 are more tha enough for what we're doing
  .flatMapMaybe { // 2nd api call with information from the 1st one
      api.getUserDetails(username.value)
          .map { detailedUserMapper.mapToEntity(it) }
  }
  .toList() // gather all stream events back into one list -> List<DetailedUser>
  .doOnSuccess { Logger.d("Updating database") }
  .subscribeOn(Schedulers.io())
  .subscribe(
      { updateCachedUsers(it) },
      { handleErrors(it) }
  )
  .addTo(compositeDisposable) // Extension function
```

Ok, so what's happening here?

- We get the list of users from the API through a `Maybe<List<GithubUser>>` stream;
- We flatten the list into an `Observable<GithubUser>` stream, and map each element to a domain entity called `User` (even though I'm pretending there are no boundaries, I left this mapping on purpose since it's part of the stream's operations);
- We take the first 10 elements just because we'll have to do another API call for each user, and Github has a very low limit for unauthenticated requests;
- We use flatMapMaybe to get the user details for each of the 10 users, and map each one of the returned objects (`GithubDetailedUser`) to a domain entity called `DetailedUser`. Why flatMapMaybe instead of a regular flatMap? Because the `getUserDetails` API call returns a `Maybe<GithubDetailedUser>`, and a simple flatMap requires that you provide it with the same kind of stream you apply it on, since it has to return the same type (in this case, an Observable stream). As such, flatMapMaybe is expecting a Maybe stream as its parameter, and returns an Observable stream at the end;
- After flatMapMaybe does its magic and flattens the incoming streams into one `Observable<DetailedUser>` stream, we call the toList operator, which in turn will output a `Single<List<DetailedUser>>` stream;
- Finally, we do some logging, bind the upstream to a thread from the IO pool and subscribe to the whole thing. Since the last operation outputs a Single stream, the observer only has two functions: an onSuccess lambda that calls the `updateCachedUsers` method, and an `onError` lambda that calls the `handleErrors` method. `updateCachedUsers` then proceeds to update the database with the information it gets as parameter, i.e. a `List<DetailedUser>`.

Whew. That's a whole lot of stream operations. But it does exactly what we want: it fetched data from a remote API and updates the local database, all in an asynchronous fashion. Let's see how can we do the same with coroutines.

### Handling an API request with coroutines
