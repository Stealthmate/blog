---
layout: post
title: A pattern for managing global state in software
date: 2023-11-18
---

* Do not remove this line (it will not be displayed)
{:toc}

My day job is software development, and recently (if you can call 1 year ago "recent") I discovered a way to manage all the global state in my code in a relatively clean way. I've been using it for quite a while now, and at this point I'm starting to wonder if it already has a "proper" name, whether people know about it and whether it is commonly used.

## Hidden dependencies

I assume you are already familiar with the concept of dependency --- packages, functions and other entities that your code depends on --- in software. Dependencies are what allows us to build... well, anything really. The desk that you put your monitor on is a dependency, and so is the floor on which the desk is placed. In fact, the foundations of your house are a dependency to the floor, the Earth itself is a dependency to the foundations of your house and the Big Bang is a dependency to Earth's existence, and--

The point is that there are a lot of dependencies in the world. And if you are not careful about them, the Dev Gods become very angry and eventually send you to [Hell](https://en.wikipedia.org/wiki/Dependency_hell).

Most commonly, when we say dependency, we are talking about distinct packages for a certain ecosystem such as a Linux distribution or a programming language's package index. In this 

However, we also recognize dependency relationships inside the actual codebase as well. Consider this snippet:

```python
def say(msg: str) -> None:
    print(msg)

def say_hello() -> None:
    say("Hello!")
```

I think we can all agree that `say_hello` depends on `say` in this case. However, the only way to assert that statement is to look inside the content of `say_hello` and basically find a reference to `say`.




---

_Last night I posted an article about [what image sensors actually capture]({{ site.baseurl }}{% post_url 2023-11-02-what-does-an-image-sensor-do %}). At the end of that post I said that next time I'll talk about color filter arrays. I know, and I'm sorry to tell you that this post is not about that (yet!)._

I woke up around 8:30 AM today, immediately went for a jog, came back around 9:30, took a shower and then made a decision: **_I am going to try to open a RAW file using Rust, and then render it to a PNG somehow!_**

Lo and behold, after about an hour of fiddling, I managed to do just that!

So I'm going to share my results in this post.

## The test subject

I dug around my photo directory and found this semi good-looking shot of an ancient Roman bad boy [^1] that I saw during my trip to Italy in August.

<div style="margin: 40px 0; display: flex; flex-direction: column; width: 100%; align-items: center;">
    <img height="600px" src="{{ site.baseurl }}/assets/ancient-roman-bad-boy.jpg" alt="ancient-roman-bad-boy" />
</div>

_Note: I'm using the JPG produced by the camera for this post, but the actual processing was done on the raw file (NEF)._

## The experiment

I wrote some Rust code to do the following:

1. Open the NEF file
2. Extract the raw data as it is, without applying _any_ kind of processing.
3. Encode the raw data as a PNG and save that.

For the first step, I used the [rawloader](https://crates.io/crates/rawloader) crate. The library itself seems kind of old, and I wasn't sure if it was OK to use long-term [^2], but the guy who made this had a [post on Reddit](https://www.reddit.com/r/rust/comments/6c6dxu), which had some pretty convincing positive feedback, so I decided to give it a go.

The second step was also easy enough. rawloader conveniently provides us with a [data structure](https://github.com/pedrocr/rawloader/blob/56297dad3c1bdae9c63876bde869e1df1c2f1c95/src/decoders/image.rs#L7-L43) that stores all that data in the NEF file in an easy-to-access way. In my case, initially I wanted to play around with the CFA, white and black levels, and other attributes, however I quickly realized that I don't have enough knowledge about that yet. So I decided to just dump the raw data into a PNG as it is.

Finally, for the PNG encoding I used the [png](https://crates.io/crates/png) crate. This was pretty straightforward as well - I simply copied the hello world example and changed the parameters to output grayscale.

Finally, I pushed all my code to GitHub and gave it a tag (`v0.0.1`) to act as a permalink.

Link: 
<https://github.com/Stealthmate/ripp/tree/v0.0.1>

## The result

And, here we go!

<div style="margin: 40px 0; display: flex; flex-direction: column; width: 100%; align-items: center;">
    <img height="600px" src="{{ site.baseurl }}/assets/ancient-roman-bad-boy-raw.png" alt="ancient-roman-bad-boy-raw" />
</div>

This, dear viewer, is what the camera sensor actually "sees". If you're currently thinking "what the hell is this?", then I assure you that your reaction is appropriate.

There are a few reasons that the result looks like it does. I won't pretend to understand all of them, but to give you an overview:

1. Each pixel is actually capturing data for a single color. That is, some pixels are only seeing green red light, some only green, and some only blue. This is basically the concept of the [color filter array](https://en.wikipedia.org/wiki/Color_filter_array) that I mentioned in my last post.
2. The pixels need to be adjusted so that physically "dark" areas are actually encoded as a "dark" color in the PNG, and similarly for "bright" areas. This is where black and white levels come into play, as far as I understand anyway.

I encourage you to download this image and try zooming all the way to the individual pixels. Some viewers will try to blur the pixels, but I know for sure that VS Code will show each pixel as a perfect square. Then you will be able to see that pixels next to each other have significantly different brightness, which illustrates the concept of different pixels seeing different "colors" of light.

## Conclusion

I wanted to write this post quickly, and just share what I did and the results of it. Alas, this one also took quite a bit of time. I should really stop underestimating writing...

Anyway though, I will go to my usual café now, and get lunch. It's 11:30 AM right now, and after that jog I am hungry as a wolf!

## Footnotes

[^1]: _Now that I look back on this, I seriously regret not doing a little more research/studying when I went to Rome. At least I should have remembered who the sculpture represented. Sigh..._

[^2]: _I have this grand dream of writing my own image processing pipeline and/or GUI software, so ideally I'd like to learn libraries which I can rely on in the future. Then again, this is just an experiment, so I shouldn't overthink it either._
