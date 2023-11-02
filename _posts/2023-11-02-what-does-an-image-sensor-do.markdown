---
layout: post
title: From light to pixels - what does an image sensor do?
date: 2023-11-02
toc: true
---

* Do not remove this line (it will not be displayed)
{:toc}

## Background

Have you ever wondered what happens when you press the shutter on your DSLR? What the hell is a "raw" image? Why is software like Adobe Lightroom so big, slow and expensive?

I bought my Nikon D5600 DSLR back in February 2021, and ever since then I feel like I have been running uphill when it comes to these questions. Sure, I can find _some_ answers on the Internet. And _sometimes_ it makes sense. And for all practical purposes, I can open up [Darktable](https://www.darktable.org/) and edit my photos just fine. 

But sometimes I just can't help but open up Pandora's box and jump into the rabbit hole that is digital imaging [^1].

So here I am, trying to record my thoughts in an attempt to improve my own understanding, and possibly, _just maybe_, help some other poor soul trying to navigate this part of the science and engineering world.

This series of posts is meant to be a rough overview of the main things that happen from the moment you press the shutter on a DSLR, to the moment you see the (hopefully good-looking) JPEG image on your screen. I'll try not to go into too much detail, mostly because I don't have the confidence that I won't say something wrong, but also because I want to finish each post in not more than an hour or two.

Also, this is my (almost) first time writing a blog, so my writing probably sucks. But oh well, we all gotta start somewhere.

## Overview

Let's say you are sitting at a mountain peak somewhere. You really like the view, so you take out your phone and snap a photo for your Instagram story. Pop quiz - **what just happened?**

Naturally, you might say that "the phone's camera captured the image". But if you're reading this post, you probably already realize that this statement actually doesn't really tell you much. In this post, we will try and unpack this statement into a few more meaningful steps.

As a quick overview, your phone performed more or less the following steps:

1. The electronics behind the camera lens did some magic and converted the light you see into a bunch of numbers representing the _intensity_ of the light.
2. Your phone took those numbers, did some math on them, then produced some more numbers representing the _color_ of the light.
3. Then your phone did even more math, and converted the numbers into _something that your phone's display can understand_.
4. Then your phone's display _converted those numbers into light again_ (you guessed it, using more math), and shined it onto your eyes.

Now let's explore these steps one by one. This art

## Let there be ~~light~~ voltage

You have probably already know the word _megapixel_ means. When _&lt;your favorite phone manufacturer&gt;_ says that your phone has a 48 megapixel camera, you probably already know that this means a resolution like 8000x6000, or in other words - a rectangle 8000 pixels wide and 6000 pixels tall [^2].

So your phone has 48 megapixels (that is, 48 million pixels). **But what do these pixels actually capture?**

The answer is - _voltage_ [^3].

Ok, phew. Hopefully I didn't piss off too many people. Anyway, let's continue.

So each pixel essentially produces a voltage value. In practice, this value may or may not get immediately converted to a slightly different unit as part of the electronics around the sensor. Regardless of that, there is an important realization to be made here:

**Each pixel produces a _single_ value.**

If you've ever heard about RGB, you might immediately ask: _But aren't pixels supposed to have a value for each color channel?_

Congratulations! You have now reached the first peculiarity of the digital imaging world.

Back to pixels. Remember how I said pixels capture the _intensity_ of light first? I meant that literally. The voltage output of each pixel represents how intense the light hitting the pixel was. But that tells us absolutely _nothing_ about the color of that light [^4].

Finally, it is worth elaborating on how the pixel value is being output. In the physical world, each pixel produces an analogue voltage read-out. This means that:

1. The voltage value is _continuous_, i.e. it is a real number of infinite precision.
2. The voltage value is _unbounded_, i.e. it has no minimum or maximum value.

However, from browsing a few data sheets, I found out that image sensors actually go through the trouble of quantizing this value. What this means, is that the rest of the electronics surrounding the image sensor receives a discrete digital value of fixed bit-depth. For example, my [D5600](https://www.bhphotovideo.com/c/product/1308819-GREY/nikon_d5600_dslr_camera_with.html/specs) appears to use a bit-depth of 14 bits.

The interesting part here is that this bit-depth is (at least in my opinion) almost the entire reason people recommend shooting RAW rather than JPEG. I won't go into detail about what bit-depth actually is, but in summary:

1. A device called an [ADC](https://en.wikipedia.org/wiki/Analog-to-digital_converter) is used to convert a _continuous_ and _unbounded_ value into a _discrete_ and _bounded_ one.
    - _Discrete_ means having finite precision, e.g. if precision is up to 0.01, and the original number is 0.005, then we _must_ pick either 0.01 or 0.00.
    - _Bounded_ means that there is a minimum and maximum, e.g. if the original number is -1 but the minimum threshold is 0, then we _must_ convert -1 to 0.
2. The higher the bit-depth, the more "options" we have when encoding values. In other words, more bit-depth means higher precision.
3. High precision implies that later on, when we want to _edit_ the photo, we can increase exposure without losing detail (contrast).

## Conclusion

Phew. Originally, I planned to cover all the steps in the overview section, but I started writing this at around 10pm, and right now it's almost 1am, so I'm going to cut this here. I learned a lot while writing this, but I definitely didn't expect it would take this much time and effort to explain just one of the steps, even while trying to keep things simple. Oh well.

Next time, I'm going to cover the second step - extraction _color_ from the _intensity_ captured from the sensor. This happens because of something called a [color filter array](https://en.wikipedia.org/wiki/Color_filter_array) or CFA, which sits on top of the matrix of pixels in the sensor. I conveniently left out the existence of the CFA in order to focus on the idea of light intensity, so next time I will expand that in more detail.

But now I need to sleep.

## Footnotes

[^1]: _To be honest, I think this is mostly because I read a lot of books about Lightroom, and when I tried to convert the ideas into whatever Darktable supports, I ended up realizing that I actually need (want?) a pretty solid fundamental understanding of the stuff that such software does._

[^2]: _I didn't know that, so I asked a [calculator](https://toolstud.io/photo/megaspect.php?pixels=48000000&aspect=1.333333333) for the exact numbers._

[^3]: _Disclaimer time. According [Wikpedia](https://en.wikipedia.org/wiki/Image_sensor) and a little bit of help from ChatGPT, combined with my personal physics knowledge and interpretation, image sensors work by converting photons into electrons (charge), which induces some amount of voltage which then gets "read" by the rest of the electronics. If you think this statement is wrong - feel free to enlighten me. I do not claim that my interpretation is physically correct - only that it works well enough to convey the point._

[^4]: _Actually, I am not completely sure on the exact relationship between intensity and wavelength. I tried researching this, but I found myself in yet another rabbit hole, so I will assume that they are independent for now, and read about this later._