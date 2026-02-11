---
layout: post
title: Contemplations - personal growth, accounting, and compilers
date: 2026-02-11
---

## Personal Growth

I recently left a somewhat stressful job for a more "chill" one, and after an initial phase of cooling off, I realized that I have quite a bit of free time now. On the other hand, I also realized that my resume kinda sucks. I spent a lot of years developing internal software, which is honestly kinda hard to brag about publicly. That, and most of what I did can best be described as "in-depth full-stack engineering", i.e. self-teaching my way into 5 different roles, in exchange for a total inability to prove expertise in any of them[^1]. Nonetheless, somehow I did manage to get my new company to "trust me bro", which I am very grateful for. So here I was, starting 2026 at a fresh office, but also reflecting on 2025 and trying to figure out how to not end up in the same situation as before.

> What can I do right now, which will give me some guarantee that I can find a decent job, should that time come again?

That was the main question on my mind in January. Fortunately enough, for the past couple of years I had been playing around with a certain idea, which would eventually bloom into what I'm going to talk about in this article.

## Accounting

Have you ever heard of [plain text accounting](https://plaintextaccounting.org/)?

I'd really like to go into the details of what accounting is, as well as the motivations for plain text accounting, however that would make this article unnecessarily long. So I'm going to just assume that you have used PTA tools before, and get directly to the point.

For the past few years I have been recording all my financial transactions using [hledger](https://hledger.org/). As far as I know hledger is itself based on [ledger](https://ledger-cli.org/), which is basically the OG of plain text accounting. The concept is quite simple - record transactions in text files, then use simple CLI tools to perform common aggregations like computing balance sheets, cashflow statements and so on. A very classic take on the [UNIX philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) indeed.

Back when I only had basic knowledge of double entry accounting, hledger did a pretty good job for me. But then I took the 日商簿記 2 級 exam[^2], which introduced me to managerial and cost accounting. I also [read quite a few books](https://stealthmate.github.io/personal-library) on the subject, including [some stuff by Eli Goldratt ](https://en.wikipedia.org/wiki/Throughput_accounting). This entire endeavour culminated in me spending about 10 months working as a financial analyst - something that was almost completely unrelated to my background in software development.

Surprisingly enough, this jump between fields turned out to be quite the enlightening experiment. Looking at it from a developer's perspective, my job in the finance department was to aggregate financial data based on whatever criteria the executives cared about at the time. Sometimes it was time and/or amount. But other times it was things like whether expenses were planned or not. Or whether they were part of project X or not. Or whether they were considered counted towards [EBITDA](https://en.wikipedia.org/wiki/Earnings_before_interest,_taxes,_depreciation_and_amortization) or not. Looking at it that way, my job resembled a lot what software people might call a "data analyst". In fact, at some point I started using Python and Jupyter - not because I was asked to or because I wanted to learn new skills, but purely because of the convenience that [Pandas](https://pandas.pydata.org/) brings when working with big tabular data.

Armed with this new experience, I had a somewhat intriguing revelation. Hledger and the other PTA tools that I knew of, were really ways of digitizing a paper journal. Transactions had a date, some postings (credits/debits to various accounts), and an optional memo. The tool took care of ensuring transactions are balanced, and it could automatically calculate balances or do some basic filtering, but that was pretty much it. On a fundamental level, transactions are simply spreadsheet cells with a date and some checks included. But what I really wanted, both in my job and in my private ledgers, was the ability to tag transactions with arbitrary data, and later on aggregate them based on that. In simpler terms - first-class metadata. And while [this is technically supported in hledger](https://hledger.org/tags-tutorial.html), at least to me it feels like something patched in rather than a fundamental feature.

There was also something else. In my finance days, I found myself having to manually replicate certain transactions on regular intervals. Again in hledger this is achievable using [periodic transactions](https://hledger.org/1.51/hledger.html#periodic-transactions), but it does feel like a hack. _But by that logic, everything is a hack!_, I hear you say. Well, allow me to debate that for a moment.

Earlier I mentioned that PTA tools are ways of digitizing a paper journal. If we take that idea to the extreme, then they shouldn't really be performing any checks, since a paper journal cannot automatically check its contents. Obviously this wouldn't be very useful though. So then let's consider the opposite side. What if we could envision a tool which could _encode_ a journal in such a way that ensures that its contents are correct? What if our tool was no longer just a substitute for the paper, but also for the person reading from/writing to it? What if our digital journal was not just the _raw data_, but the _source code which generates the raw data_?

Obviously this opens up a huge can of worms about how much such a journal can be trusted. After all, if we allow a journal to _generate_ data, it gets a lot harder to reason about whether that data is correct or not. But then take for example YAML. YAML supports some minimalistic code generation using [anchors](https://yaml.org/spec/1.2.2/#3222-anchors-and-aliases), and it is still used in a lot of places. If someone made a journal format using a similar approach - where you are allowed some automation, but not enough to break trust in a significant way - then maybe such a format could prove useful?

## Compilers

Back in 2018, I started my first part-time job as a web developer. Using Haskell. This was a very eye-opening moment for the 20 year old kid with 5 "years of experience" writing hobby projects in C++, Java, Python and Lua, none of which had anything to do with the word "functional" at the time. Irony aside, that job gave me a very brutal but solid background in Haskell and functional programming in general, which later motivated me to experiment with parser combinators. I don't really remember exactly what I was experimenting with at the time, but it was enough to give me a very basic understanding of parsers. And it also taught me a vaulable lesson.

> Languages are hard. Parsing them is even harder. Whenever you need a DSL, use a host language that already has a mature toolchain.

This lesson served me well in both my work and private life. I managed to avoid quite a few rabbit holes by simply convincing people to use YAML or TOML or whatever, for stuff that could have ended up as a suspiciously-implemented in-house DSL. But it also put on me a limitation, which I didn't really recognize for a long time. The limitation that I didn't have the necessary skills to solve problems which did require a real DSL. For example, having the ergonomics of a custom syntax, while also providing interoperability with common formats such as JSON, YAML, etc. I suppose at this point you already know where I'm going with this.

And so, in January 2026 I started working on a pet project called [boki](https://github.com/Stealthmate/boki)[^3]. Boki is meant to be a DSL/toolchain similar to hledger, but solving the problems I mentioned in the above section. It's also meant to be an exercise in writing compilers. Something that I can put a lot of work in, and hopefully be able to brag about later on. As I mentioned above, I've had somewhat of a knack for compilers ever since I learned Haskell. And I finally have some real free time. So I figured I'd write boki as a way of experimenting with my accounting ideas, while also learning in-depth about compilers, and hopefully being able to use the result in my resume in the future.

That being said, boki is still nowhere near complete enough for me to "announce" anywhere officially. It's been only a few weeks since I started working on it, and I had to rewrite big chunks of it multiple times already. In fact, I'd like to go into the details of parsing and lexing and whatnot right here, but I have nowhere near enough knowledge to be talking about this publicly yet. Still, it's also getting to the point where I can barely hold back from flooding my friends' conversations with my rambling about the subject, so I figured I'd let it all out here in the open and hope that someone finds my ideas interesting enough to entertain in discussion. That, and I also wanted to describe somewhere my motivation for starting the project, so I figured writing this article would be a decent step in that direction.

What I'm _not_ concerned with, is boki's utility. Obviously I would like to be able to use it for my own stuff, but I've decided to actively ignore other similar projects. I would feel really nice if I manage to invent a new wheel, but honestly me real goal is to learn the mechanics rather than getting paid or becoming famous. So I'm okay with the possibilty of ending up reinventing an existing wheel. Or at least that's what I need to tell myself so that I don't simply give up.

---

[^1]: I shit you not, when I told my to-be boss that "[I developed the VPN authentication mechanism for my company basically by myself](https://stealthmate.github.io/experience/auth-server.html)", he looked at me as if I was a Nigerian prince.

[^2]: This is a Japanese exam which literally translates to "bookkeeping exam level 2". Very basically, it tests your understanding on correctly recording business transactions, but level 2 also covers cost accounting. 

[^3]: _boki_ is the romanization of 簿記, which is the Japanese word for bookkeeping.
