---
layout: post
title:  Stateless classes - a way of writing functional code in an object-oriented language
categories: jekyll update
---

Disclaimer:

I wrote this mostly as a way of organizing my own thoughts. I have been reading about this subject quite a lot, and, as of the time of writing this, I have not found anyone person or text discussing the ideas in this post in detail. If you know of any literature that presents the topic more formally, please do let me know - I would be happy to read about it!

## Background

Back in 2018, I started work at a startup that had a lot of Haskell code. This was my first exposure to functional programming, and I spent 1~2 years working there. My mentor there (who also doubled as CTO) was a really experienced Haskell geek, and he taught me a lot about the language. Most importantly, he introduced me to a style of code that I still draw inspiration from, to this day.

On the other hand, these days I do most of my work in Python. I've been working for my current company for about 3 years now, and at this point I have seen and written a _lot_ of Python. I am proud to say that every time I have to look at my code from 3 years ago, I get mild but firm symptoms of anxiety - I consider that as indication that I've grown since then, hence feeling proud.

But anyway, these past few months I've been converging on a certain pattern when writing code. And the funny thing is - this pattern is, in my experience, quite language agnostic. The original inspiration of course comes from Haskell, but I've managed to replicate the idea in Python and even Rust! Granted, in Rust it feels a lot more natural than Python.

Enough about myself. Now let's dig into it.

## The Basic Concept

The basic idea I want to convey in this post is that **classes can be viewed as simply a way of organizing function arguments**. This sounds somewhat unrelated to the title, but I'll try and explain myself in the following paragraphs, so that hopefully you, dear reader, will understand why I picked my words like this.

Let's start with an example. Consider the following Python function:

{% highlight python %}
def add_two_numbers(x: int, y: int) -> int:
    return x + y
{% endhighlight %}

Nothing strange here. Now consider the following class:

{% highlight python %}
class AddTwoNumbers:
    def __init__(self, x: int, y :int) -> None:
        self.x = x
        self.y = y
    def run(self) -> int:
        return self.x + self.y
{% endhighlight %}

There is a lot of boilerplate here, even though the function is dead simple.

I think it's safe to say that in this particular case, 99% of people will write the function instead of the class. But let's ignore the practicalities for a moment and focus on 