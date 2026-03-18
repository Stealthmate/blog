---
layout: post
title: Source code as a data format - Parsing my own DSL in Rust and how it changed the way I think about languages
description: Learn about how domain-specific language toolchains can be seen as a data pipeline, how source code can be used as a way of compressing the transfer of data between human and machine, and how these ideas influenced the development of Boki - a new tool for doing plain text accounting.
date: 2026-03-26
---

A few weeks ago I posted [an article]({{ site.baseurl }}{% post_url 2026-02-11-growth-accounting-compilers %}) about how I had some spare time and decided to work on a new toy project &ndash; a parser[^compiler-or-parser] for my own custom DSL (domain-specific language) to do plain text accounting. I named this project [Boki](https://github.com/Stealthmate/boki) and spent around 80 hours working on it[^80hrs]. As it often goes with programming, I spent a lot of those hours experimenting with and refining the conceptual model (the _domain_, in DDD terms) of what I was trying to build. Given that I had never done any serious language design before, this endeavour turned out to be quite the deep rabbit hole, but fortunately I managed to eventually get out of it and produce a decent-working tool. Further, it taught me a lot about languages, parsing and data in general, so here I am, as usual, trying my best to distill my learnings into a blog post.

## Why build a DSL?

As a firm believer of Simon Sinek's [Start With Why](https://www.amazon.com/dp/1591846447) approach, I'm going to start this article with exactly that question.

_Why did I go through all the trouble of building a custom DSL?_

There were a few reasons for that, but in a nutshell it boils down to me wanting to develop new skills and put into shape some ideas that I'd been playing around with in my head for a while. Since the point is to learn stuff, I don't intend for this project to become anything practically useful (although I would certainly be happy about such a development). That being said, I do think there is a case to be made for choosing to develop a new DSL rather than using existing tools, so in this article I'd like to start by expanding on that a bit.

For a long time in my software career, I was very much against the idea of stand-alone DSLs &ndash; that is, languages which define their own syntax and require their own toolchains. Back in my university days, inspired by my part-time job at a Haskell shop, I spent some time playing around with [megaparsec](https://hackage.haskell.org/package/megaparsec) &ndash; a parser combinator library for Haskell. On the one hand, this was very interesting &ndash; I still remember the euphoria I got when I finally implemented infix arithmetic correctly, after struggling with recrusion traps for hours. On the other hand &ndash; it gave me the valuable lesson that _languages are hard_. Like, _really hard_. It takes a lot of time to develop one, and there are a lot of edge cases to consider, so developing a new one is definitely not something I would want to approach lightly.

This lesson served me well throughout the years. Whenever I would run into a situation where someone would even slightly start hinting at a custom language (or custom data format for that matter), I would immediately think: How hard would it be to instead use YAML as a host? Or TOML. Or anything really, as long as it was well-known, well-maintained and well-supported. Surely enough, most of the time my colleagues and I would come to the realization that yes, existing languages can do the job just fine[^dsl-ocd].

So then, given my background in fiercly rejecting the idea, why did I decide to _not_ use [existing tools](https://plaintextaccounting.org/) and instead roll my own DSL? Ignoring the part about doing it as an exercise, I did have a few "real" reasons as well. To explain those however, I need to talk a bit about the actual domain.

I keep a general ledger with all the financial transactions that happen in my personal life, and I also do quite a bit of data analysis on that. Existing tools do a good enough job for basic things like calculating balances and cash flows, but when it comes to more involved computations or charts you end up needing other tools. In my case, I would export my data into JSON, load it into Python and then use libraries like [Pandas](https://pandas.pydata.org/), [Plotly](https://plotly.com/) and [Streamlit](https://streamlit.io/) to manipulate the data and make pretty plots out of it.

In order to do this efficiently, I need two things &ndash; a way to easily record whatever I want to record and a way to get the data into an easy to process format. At one point I considered recording everything in YAML &ndash; a format which is both easy for humans to read/write and also produces well-defined data structures[^antiyaml]. The problem with YAML is that, while easy enough to read, it is still too verbose when used to record data with a mostly predefined structure. Consider this list of transactions:

```yaml
- date: 2026-01-01
  description: Drinks at the local pub
  postings:
    - account: assets/cash
      currency: JPY
      amount: -5000
    - account: expenses/food
      currency: JPY
      amount: 5000
- date: 2026-01-02
  description: A new PC
  postings:
    - account: assets/savings
      currency: JPY
      amount: -200000
    - account: expenses/qol
      currency: JPY
      amount: 200000
- date: 2026-01-03
  description: Groceries
  postings:
    - account: assets/cash
      currency: JPY
      amount: -5000
    - account: expenses/food
      currency: JPY
      amount: 5000
```

That's 633 characters total, with 237 being used for metadata (attribute names). In other words &ndash; about 37% of what I write would be stuff I don't care about! This was enough reason for me to drop the YAML idea. Instead, I decided to use [hledger](https://hledger.org/) for recording transactions. Written in hledger syntax, the same data would look like this:

```
2026-01-01 ; description:Drinks at the local pub
  assets/cash      JPY    -5000
  expenses/food

2026-01-02 ; description:A new PC
  assets/savings   JPY  -200000
  expenses/qol

2026-01-03 ; description:Groceries
  assets/cash      JPY    -5000
  expenses/food
```

Looks a lot more concise, doesn't it?

Hledger works fine when it comes to core functionality, but these days I heavily rely on tags, which I use to record various metadata[^metadata]. The problem with tags is that in hledger they seem to have been implemented as somewhat of an afterthought. They do _work_, but since they're implemented as an add-on to regular comments (`;` is the comment marker), they tend to have some of their own intricacies which end up causing trouble sometimes.

Lacking any other good ideas, I decided I might as well channel my annoying dissatisfaction with existing tooling into something positive. I had some free time on my hands and I wanted to sharpen my developer skills. I'd always had a fleeting interest in languages and now I also had the use case for building one. Sure, I could take the rational approach, do some more research and _maybe_ find a tool which solves my problem without any annoyances. But rationality is for work. I wanted to do the dumb thing for a change.

So yeah. This is why I decided to yolo it, roll my own DSL and tell the world about it.

## Is it code or data?

After a brief coding session in which I tried hacking together a minimalistic parser (and realized it ain't gonna be that simple), I went to the drawing board and started thinking about the high-level purpose of my to-be language. _What is it, exactly, that I want to accomplish with this?_[^goal-setting]

In order to explain how I answered this question, it helps looking at a concrete example. In hledger, you can declare so-called _periodic transactions_. A periodic transaction is exactly what it sounds like &ndash; the same transaction recurring at some pre-defined interval. Taken straight from [the official docs](https://hledger.org/1.51/hledger.html#periodic-transactions), a periodic transaction looks something like this:

```
~ monthly from 2023-04-15 to 2023-06-16
    expenses:utilities          $400
    assets:bank:checking
```

**Would you consider this _code_ or _data_?** Honestly, I don't think there is a black-or-white answer to this question. Depending on your exact definitions for code and/or data, either could be a correct answer. I do, however, think that, given that we're discussing this within the context of _accounting_, there are certain considerations which favor one answer over the other. In particular, I personally believe that anything related to accounting needs a high level of _correctness_. Case in point &ndash; you wouldn't want the credit card company to deduct more money from your bank account than you actually owe, would you? In other to ensure such correctness, I would argue that any kind of accounting _data_ should be _specific_ and _explicit_. _Specific_ as in unambiguous and having only one valid interpretation, and _explicit_ as in requiring little to no effort[^error-opportunity] to interpret. Examining the above example through these two lenses, we can say that it certainly is specific, but it also does contain some amount of implicitness - it looks like 1 transaction, when in reality it represents 3 of them. Therefore, I would argue that a periodic transaction in hledger leans more towards being _code_ rather than data.

Naturally, I had to make the same judgement call for Boki. Do I want it to be a tool for writing _code_, or a format for storing _data_? Well actually, I wanted it to be a little bit of both. To quote myself from the previous section:

> In order to do this efficiently, I need two things &ndash; a way to easily record whatever I want to record and a way to get the data into an easy to process format.

Right now this looks like a generic user requirement, so let's try to translate it into "proper" software development lingo. _A way to easily record whatever I want to record_ is a statement related to _writing_ data. The user here is just a regular person who wants to keep a log of their expenses and spend spend as little time as possible doing it. They certainly do care about their data being correct, but being explicit is not a direct requirement. In fact, the more specific and explicit they have to be, the more time they would have to spend on writing data, which is actually an anti-requirement. Thus, we can infer that such a user would probably prefer using _code_, albeit only to the extent that it reduces time spent writing data, without incurring extra time to ensure the correctness of the code itself (in other words &ndash; code that's simple enough to write without bugs on the first try). On the other hand, _a way to get the data into an easy to process format_ is a statement about _reading_ data. The user wants to read the data into an external tool and do various kinds of analysis on it. For that, they need the data to be portable. But by definition, all newborn languages are _unportable_ - at first, they are only supported by the tools their creator provided. Therefore, if our user were to record their data in Boki, they would also need a way to export that data into an already portable format (for which I chose JSON). I like to imagine this in the following way:

<div style="margin: 40px 0; display: flex; flex-direction: column; width: 100%; align-items: center;">
  <img height="600px" src="{{ site.baseurl }}/assets/cqrs.svg" alt="A diagram of how the user interacts with data. Red arrows represent reading, while green ones represent writing." />
  <figcaption style="text-align: center;">How the user interacts with data.<br />Red arrows represent reading, while green ones represent writing.</figcaption>
</div>

This kind of approach &ndash; dealing with _reading_ and _writing_ as separate concerns &ndash; was actually something I first learned when I stumbled upon the concept of [command query responsibility segregation](https://martinfowler.com/bliki/CQRS.html) (CQRS) and [back-end for frontend](https://samnewman.io/patterns/architectural/bff/) (BFF) pattern in my web dev days a few years ago. Applying the same ideas here, what I ended up doing was to essentially provide two different ways of working with the same underlying data &ndash; the human user would work with the Boki code, and analysis software would work with the JSON representation. The key part is that Boki code and the JSON representation would both be ways of encoding the same _abstract data_, that is the actual transactions, differing only in the specific syntax used to encode that data.

## Parsing as a data pipeline

Now that I had figured out the high-level philosophy behind Boki, it was time to actually implement some tools for it. [Coming up with actual feature requirements](https://github.com/Stealthmate/boki/issues/31) turned out to be an interesting exercise of its own &ndash; it's been a while since I actually had to develop anything that could be considered user-facing software, so it was refreshing to play the role of a [high-tech anthropologist](https://menloinnovations.com/stories/hta/so-what-exactly-is-a-high-tech-anthropologistr), albeit only by myself. In the end, I ended up focusing on two main features - a way to export source code to JSON (duh!) and a way to automatically format the source code files. Coincidentally, this combination turned out to be the perfect way to force myself to learn, yet again, that languages are hard.

Before I go into the main ideas of this section, I'd like to quickly go over the things I _won't_ be writing about first. Writing my first proper toolchain from scratch, I went through an obligatory struggle with all the usual concepts regarding languages &ndash; lexers, parsers, why you need them, how they differ from each other, and so on. I also got to face head-on the problem of practicality &ndash; that is, implementing a parser which doesn't just declare a piece of source correct or incorrect, but tells you where and what kind of errors there are (and possibly how to fix them). All that being said, I suppose these are standard pitfalls that anyone who tries to design a language goes through, so I will leave them out of this article in favor of looking at the big picture[^implementation-details].

Ok, back to the main topic. In the very beginning, when I was thinking only about the exporter feature, I envisioned my toolchain as something like this:

<div style="margin: 40px 0; display: flex; flex-direction: column; width: 100%; align-items: center;">
  <img src="{{ site.baseurl }}/assets/boki-toolchain-v1.svg" alt="A diagram of the first iteration of the Boki toolchain, showing the relationship between Parser, Compiler and Exporter stages." />
  <figcaption>Boki Toolchain, version 1</figcaption>
</div>

For reasons that I won't go over (see paragraph above), I quickly realized that I would significantly benefit from a lexing stage.

<div style="margin: 40px 0; display: flex; flex-direction: column; width: 100%; align-items: center;">
  <img src="{{ site.baseurl }}/assets/boki-toolchain-v2.svg" alt="A diagram of the second iteration of the Boki toolchain, showing the relationship between Lexer, Parser, Compiler and Exporter stages." />
  <figcaption>Boki Toolchain, version 2</figcaption>
</div>

This kind of structure allowed me to implement the exporter feature just fine. The Lexer would convert text into well-typed tokens. The Parser would convert a stream of tokens into a bunch of nodes. The Compiler would then ingest those nodes, fill in all the omitted (but deterministically implied) data[^omitted-data] and produce an internal representation of the final data. Lastly, the Exporter would convert the internal representation into JSON and print that to a file, which I could then load into Pandas and use for whatever analysis I deemed necessary! Further, adding location information to all tokens and nodes would allow me to trace back any errors that happened back to the original text source, so I could even produce decent error messages.

Long story short, I made a tool which could turn this:

{::options parse_block_html="true" /}

<details>
<summary markdown="span">Boki Syntax (click to expand)</summary>

```
set default_commodity USD // Any time we do not specify a commodity, boki will assume we mean USD.

// We also support multi-byte characters: 🎉 万歳！

2026-01-01
  // You can include arbitrary YAML segments in transactions!
  ---
  book: The Art of Computer Programming 1
  new: true
  topics:
  - Software
  ---
  assets/cash  ; USD ; 80 // Here we explicitly specify the commodity
  expense      ;     ;    // Here boki automatically balances the transaction, assuming the default commodity we specified earlier

2026-01-02
  ---
  book: Harry Potter and the Philosopher's Stone
  new: false
  ---
  assets/cash  ;     ; 16
  expense      ;     ;

2026-01-03
  ---
  book: The Mythical Man-Month
  new: true
  topics:
  - Software
  ---
  assets/cash  ;     ; 20
  expense      ;     ;

2026-01-04
  ---
  book: The DevOps Handbook
  new: false
  topics:
  - Software
  - DevOps
  ---
  assets/cash  ;     ; 30
  expense      ;     ;
```

</details>

into this:

<details>
<summary markdown="span">The final JSON output (click to expand)</summary>

```json
{
  "header": {
    "default_commodity": "USD"
  },
  "transactions": [
    {
      "header": {
        "timestamp": "2026-01-01T00:00:00Z",
        "attributes": {
          "book": "The Art of Computer Programming 1",
          "new": true,
          "topics": [
            "Software"
          ]
        }
      },
      "postings": [
        {
          "account": "assets/cash",
          "commodity": "USD",
          "amount": 80
        },
        {
          "account": "expense",
          "commodity": "USD",
          "amount": -80
        }
      ]
    },
    {
      "header": {
        "timestamp": "2026-01-02T00:00:00Z",
        "attributes": {
          "book": "Harry Potter and the Philosopher's Stone",
          "new": false
        }
      },
      "postings": [
        {
          "account": "assets/cash",
          "commodity": "USD",
          "amount": 16
        },
        {
          "account": "expense",
          "commodity": "USD",
          "amount": -16
        }
      ]
    },
    {
      "header": {
        "timestamp": "2026-01-03T00:00:00Z",
        "attributes": {
          "book": "The Mythical Man-Month",
          "new": true,
          "topics": [
            "Software"
          ]
        }
      },
      "postings": [
        {
          "account": "assets/cash",
          "commodity": "USD",
          "amount": 20
        },
        {
          "account": "expense",
          "commodity": "USD",
          "amount": -20
        }
      ]
    },
    {
      "header": {
        "timestamp": "2026-01-04T00:00:00Z",
        "attributes": {
          "book": "The DevOps Handbook",
          "new": false,
          "topics": [
            "Software",
            "DevOps"
          ]
        }
      },
      "postings": [
        {
          "account": "assets/cash",
          "commodity": "USD",
          "amount": 30
        },
        {
          "account": "expense",
          "commodity": "USD",
          "amount": -30
        }
      ]
    }
  ]
}
```

</details>

{::options parse_block_html="false" /}


The fun part came when I started working on the formatter feature. At first I figured I could simply work off of my existing setup &ndash; take a stream of nodes and just pretty-print them as Boki source code. And then I quickly realized that my Node structure had no way of encoding comments. Or lines that contained only comments. Or any other kind of syntax that is irrelevant to the exporter, but very relevant to whoever reads and writes the source code. Woops!

I had to make a choice &ndash; I could either add a way of encoding syntax into my Node structure, or I could roll an entirely separate Parser component just for the formatter. At first, the former approach sounded simpler, but the more I considered it, the more I started to have doubts &ndash; the more types of Nodes I supported, the more complicated the Compiler stage would become. Given that the entire point of the Parser stage was to make it easy to do the Compiler stage, this apporach sounded quite counter-productive in the long run. On the other hand, implementing a dedicated Parser component for every different feature I needed sounded like a lot of extra work, to say the least. After all, the point of implementing formatting right next to exporting was precisely to take advantage of common code.

Fortunately enough, I managed to find a solution to this dilemma. I ended up picking the latter approach &ndash; having separate dedicated Parser components for the exporter and formatter &ndash; but also extracting the common logic between them into a dedicated module of its own. In essence, I made sure that _constructing multiple parser components was easy_. This way, I could have a simplified Parser that parsed just enough information to make formatting feasible, as well as a stricter, more complicated parser that produced nodes clean enough to make the Compiler stage easy as well.

<div style="margin: 40px 0; display: flex; flex-direction: column; width: 100%; align-items: center;">
  <img src="{{ site.baseurl }}/assets/boki-toolchain-v3.svg" alt="A diagram of the third iteration of the Boki toolchain, showing the relationship between Lexer, Formatter Parser, Formatter, Compiler Parser, Compiler and Exporter stages. The Formatter Parser and Compiler Parser both depend on a ParserUtils module." />
  <figcaption>Boki Toolchain, version 3</figcaption>
</div>

Going through these iterations of my design, I realized more and more that all those concepts like _source code_, _lexing_, _parsing_, _abstract syntax tree (AST)_ and so on aren't really clearly defined. Instead, for every stage of my toolchain I had to define, using my own judgement, how much information I wanted to discard (e.g. throwing away comments), how much information I wanted to store explicitly (e.g. storing timestamps as actual datetime structures instead of strings) and how much validation I wanted to perform (e.g. ensuring that a transaction is balanced). I used to think of an AST as a data structure with a more-or less universal definition, when in reality it was simply a _convention_ that a lot of languages happened to follow in a similar fashion.

This realization lead me to see my project as not just a simple _parser_, but rather a _data pipeline_. All those lexing and parsing and compiling components were really just transforming data from one format to another, erroring out in cases where such a transformation would be impossible. Combined with the idea that I could (and actually _had to_) define each stage by myself, this really opened my eyes and allowed me to see the infinite possibilities when it comes to designing Boki and languages in general.

I know this may sound more spectacular than it is, especially from the perspective of someone who already has experience with language design. But I hope you appreciate the theoretical beauty of viewing language toolchains through such a lens. Once you start thinking about it as a data pipeline, once you realize that you can go way beyond simple lexing and parsing, things really start to get interesting. For example, consider the version 3 diagram again. I ended up implementing separate Parser stages for the exporter and formatter features. What I could have done instead is implement parsing in 2 consecutive stages - one that keeps track of the original syntax but also encodes larger structures (e.g. a transaction block), and one which strips away the original syntax. Then, I could have made it so that the formatter depends on the former and the exporter on the latter, something like this:

<div style="margin: 40px 0; display: flex; flex-direction: column; width: 100%; align-items: center;">
  <img src="{{ site.baseurl }}/assets/boki-toolchain-vx.svg" alt="A diagram of a fictional version of the Boki toolchain, showing the relationship between Lexer, Concerete Parser, Abstract Parser, Formatter, Compiler and Exporter stages. The Formatter depends on the output of the Concrete Parser, while the Compiler requires data to pass through the Abstract Parser as well." />
  <figcaption>Boki Toolchain, version X</figcaption>
</div>

Tell you what, we could even implement a way of going from JSON back to source code!

<div style="margin: 40px 0; display: flex; flex-direction: column; width: 100%; align-items: center;">
  <img src="{{ site.baseurl }}/assets/boki-toolchain-vy.svg" alt="A diagram of a fictional version of the Boki toolchain, showing the relationship between Lexer, Concerete Parser, Abstract Parser, Formatter, Compiler, Exporter, Importer and Decompiler stages. The Importer converts JSON to Raw Data. The Decompiler converts Raw Data into Concrete Nodes, which the Formatter can then use to generate Boki source code." />
  <figcaption>Boki Toolchain, version Y</figcaption>
</div>

Looks simple enough, right? Just change some of the intermediate data formats and re-connect the components. I used the terms _Concrete Parser_ and _Abstract Parser_ out of contextual convenience, but even if I called them something like _Frumbler_ and _Sproggler_, the diagram would still (more or less) make sense! Sure, it might take a while to write all the code for it, but the mental model is about as simple as it gets. This simplicity is exactly what I _couldn't_ see when I was still thinking about languages in terms of a lexer, parser and an AST[^concrete-syntax-tree].

## Source code as a format for compressed data

Hopefully by this time I've managed to convince you that source code is not really that different from normal data. In this section I'd like to argue that source code can actually be considered a way of _compressing_ data, albeit tailored towards humans rather than machines.

Let's do a quick recap first. I made Boki because I wanted:

1. a way to easily record whatever I want to record, and
2. a way to get the data into an easy to process format.

While discussing the first point, I made the following observation:

> They [the user] certainly do care about their data being correct, but [...] the more specific and explicit they have to be, the more time they would have to spend on writing data, which is actually an anti-requirement. Thus, we can infer that such a user would probably prefer using _code_ [...] that's simple enough to write without bugs on the first try.

Now let's imagine the human user as a data pipeline as well. At the very start, there are the _thoughts_ &ndash; in the context of Boki, these thoughts are the way accounting transactions are represented internally in the user's brain. While I'm nowhere near proficient enough in neuroscience to reason about exactly how accounting transactions are encoded inside the brain, I'd argue that such an encoding is at least as _specific_ and _explicit_ as the JSON files that Boki produces. When the user wants to write those transactions to a file, they must first convert them to some kind of text &ndash; in our case Boki source code. Finally, the user must user their hands to actually type that text into a computer. Naturally, the reverse of this process happens during reading, except we usually read with our eyes rather than hands[^eyes-and-hands]. All of this could be represented by the following diagram:

<div style="margin: 40px 0; display: flex; flex-direction: column; width: 100%; align-items: center;">
  <img src="{{ site.baseurl }}/assets/human-toolchain.svg" alt="A diagram of a pipeline, similar to the previous ones, showing how data flows through the human user. The Brain acts as a transcoder, converting thoughts (considered equivalent to JSON) into imagined text (Boki source code). The eyes and hands also act as a transcoder, converting between imagined text and characters in a text file." />
  <figcaption>The Human Toolchain</figcaption>
</div>

I hope you will agree with me when I assert that, given sufficiently simple source code (that is, code which is simple enough to write without bugs on the first try), the brain is usually magnitudes faster in processing speed than the eyes and hands. That is, the bottleneck is in the latter. In order to optimize this bottleneck, we would need the Boki source code to minimze the amount of characters the user has to read or type, while ensuring that it never becomes complicated enough to make the brain a bottleneck. Doesn't this remind you of how data compression works?

As it was the case with the ideas I mentioned in the previous sections, this realization was, again, eye-opening for me. Up until I started working on Boki, I had always thought of source code as something made for _machines_. Yet thinking about it as a medium of transferring thought between a human and a machine, you could just as well argue that the reason source code exists is exactly because of _humans_ &ndash; after all, machines work just fine with languages like JSON, or even binary. Thinking about it this way, maybe there is a case to be made for using DSLs _more_ rather than less &ndash; not as a way of replacing generic tooling entirely, but rather as a way of making repetitive interactions between humans, especially _non-developers_, and machines simpler, faster and more efficient, similar to how [compressing HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Encoding) makes the web faster. Maybe, just maybe, if we could teach the average person how to work with basic text files in a basic text editor, we could get away with lot less complicated, hard-to-build and often hard-to-use GUI software, and a lot more simple, straightforward, easy to manipulate text files.

Or maybe that's just my bias as a developer bored enough to be building toy languages.

---

[^80hrs]: Yes, I actually counted!

[^compiler-or-parser]: In the original article I used the word _compiler_, but in retrospect I think that is a somewhat misleading choice. According to my research it is commonly associated with CPU-level machine code, and neither my DSL nor its output have anything to do with that. Therefore I'm going to be referring to the project as a _parser_ from here on.

[^dsl-ocd]: I was so allergic to custom formats that, when I saw a colleague using environment variables for an app's configuration &ndash; as it is standard practice in many open-source projects &ndash; and parsing numbers, splitting on commas, etc., I started convincing him to stop doing that and start using TOML instead. The surprising part is that he actually changed his mind!

[^antiyaml]: I'm well aware of the [controversies](https://noyaml.com/) behind YAML, but at least in my experience it does a good-enough job when working with simple and well-defined data (or at least the data I tend to use it for anyway).

[^metadata]: Transaction metadata is actually a separate rabbit hole, which I explored in my [previous post]({{ site.baseurl }}{% post_url 2026-03-17-accounts-are-not-enough %}).

[^goal-setting]: Throughout the years, as I learned more and more about software development, how to use different languages, how different libraries and ecosystems work, etc., I realized that I can build pretty much anything, should I put my mind on it. As this happened, I found I pretty much stopped asking the question _How do I build X?_, and spent a long time figuring out _How much of X do I actually want to be building?_ That is to say, I knew I could solve my problems in many different ways &ndash; the trouble was figuring out a way that wasn't overoptimized for the immediate task at hand, but could be reused for other tasks (possibly by people other than myself) as well.

[^error-opportunity]: ...and the implied opportunity for error, borne either from negligence (bugs) or malice (vulnerabilities).

[^implementation-details]: Although if you are interested, please feel free to look through [the backlog](https://github.com/Stealthmate/boki/issues?q=is%3Aissue%20state%3Aclosed) &ndash; I used it as a way of journalling my thoughts during implementation, so it should serve as a good overview of all the problems I encountered and the ways I solved them.

[^omitted-data]: Here, the pharse _omitted but deterministically implied_ basically means the same as syntactic sugar. If you take a look at the source code examples, you will see that, for example, the currency used for each transaction can be omitted if it can be inferred from the rest of the source. Similarly, since every transaction must be balanced (that is, all the amounts in it must add up to zero), it is possible to omit one of the amounts without actually losing information. 

[^concrete-syntax-tree]: I did see someone mentioning a _Concrete Syntax Tree_ while doing research, but at the time this term made about as much sense to me as the concept of an abstract syntax tree &ndash; that is, at the end of the day there was no clear definition of it anywhere, so I had no idea what I would need one for.

[^eyes-and-hands]: It is perhaps somewhat amusing to note that my brain initially asked the question _Is there an edge case to this?_, before inevitably remembering that blind people do actually read with their hands.