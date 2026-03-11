---
layout: post
title: Accounts are not enough - What 9 months of managerial accounting taught me about financial data
description: Learn about some of the pitfalls of managerial accounting and how to avoid them without unnecessary complexity.
date: 2026-03-17
---

## The Prologue - Software engineer dives head first into finance

Back in November 2024 I decided to do an experiment. At the time, I was in a large company doing some basic internal tooling development. Just your standard software engineering job, involving a good amount of front-end, back-end and DevOps work. For better or worse, that was somewhat underwhelming for me and so oftentimes I would daydream about doing something else.

One day I was browsing through my company's internal job board, and I stumbled upon a certain managerial accounting position. I had a colleague in that department, so I sent him the link and asked: _Do you think I could do this kind of job?_ He gave me a very assuring "yes". He also turned out to be involved in the hiring process, and so a few months later, starting from April 2025, I took off my programmer hat and became a Financial Analyst.

This career jump was not entirely unplanned. I had spent most of 2024 studying bookkeeping[^exam], and the reason I knew my colleague in the first place was because I had previously looked for a person whom I could discuss my studies with. Nonetheless, during the 9 months that followed I had the chance to gain some practical experience in the field, which I couldn't really get from books alone.

As a financial analyst, I had a few different responsiblities. I was responsible for overseeing the technical infrastructure department's budget[^cloudcosts]. I had to come up with a scheme to allocate internal tooling costs to profit centers, that is to say basically figure out how to split the data center electricity bill between all the company's business units. At one point I was also involved into calculating ROIs and analyzing the entire company's financial data in order to figure out what systems and processes are costing us more money than they save. Needless to say, all of this was quite new to me.

On the other hand, my software engineering background made a lot of things easier as well. Having an intuitive understanding of how public cloud and SaaS pricings work, I think I had it way easier than my colleagues when designing the allocation schemes. More than that, my development experience made it easy for me to differentiate between technical and domain issues[^techdomain]. Armed with such insights, I spent quite a lot of time thinking about the problems the company had, what they were rooted in, and how we could potentially solve them. And while I did reach a point where I could identify problems hiding pretty deep inside the way the company worked, unfortunately I ended up switching jobs before getting a chance to work on any of them.

So here I am, a few months after I went back to software, reflecting on my days as a financial analyst. I decided to write this article as a way of codifying all the ideas that I got during that time, with the hope that putting them out in the world will be of use to someone somewhere.

# Enterprise-grade pen and paper

As a financial analyst, my first and main assignment was to oversee the technical infrastructure department's budget. Whenever someone from the department wanted to spend company money, they had to run it by a team of people, headed by myself, and then we had to make sure the expense was either already budgeted, or management was otherwise made aware of the amount and implications. The way we did this was by cross-referencing every expenditure request with a list of uniquely numbered _things_ which had monthly budgets assigned to them. I say _things_ because there was no clear definition of what a _thing_ was - in practice, our working definition was that a _thing_ was a row on our spreadsheet with a number on it. In order to avoid confusion, I will call these _budget items_ from now on.

Once I got involved in this, I immediately spotted a problem. Our spreadsheet listed all the total budgets, but it didn't provide a way to tell how much of a budget was already spent. We had one text column titled _Notes_, where some people (but not all) would write memos with the amount they had used up along with their request ID. This was fine when a request used up the budget in one go, but if a budget was used up over the course of multiple requests, then I basically had to manually calculate the remaining amount in my head each time. Needless to say, for my software engineer mind this screamed inefficiency.

Fortunately I had a solution in mind. Just a month before I started finance work, I had passed the bookkeeping exam. Naturally, as a person who just got their brand new hammer, a lot of things looked like nails to me. And my newfound problem was indeed very nail-like. I decided to start keeping a simple journal/ledger of all the requests I received. Each budget item would be an account, and the total budget for that budget item would be the initial balance of the account. Then, for each request, I would deduct the required amount from the budget item and update the balance, just like you would in a regular accounting ledger[^analogy].

Surprisingly enough, this worked. Given that I conceived the idea in less than a month on the job, it was indeed surprising. Before I started the journal, I would spend quite a bit of time doing manual calculations and trying to get information from people who knew the exact details of each budget item. After I started, each request required about a minute of work - checking the latest balance, calculating the new balance and writing out the transaction. My job turned from an everyday social adventure into boring and mundane work almost overnight.

At this point I'd like to point out that the company I worked at was _big_. We had thousands, tens of thousands of employees. We had enough money to pay those people above-market salaries, and we also had enough money to spend on both software and hardware. We had _multiple_ "enterprise-grade" systems, with as many bells and whistles as you could possibly imagine. We had whole teams working on those systems. Hell, at one point we were even paying consultants to help with future development. Yet here I was - the newbie of the month, handling requests basically instantly while my coworkers would take hours and I did it all using just the digital equivalent of simple pen and paper[^hledger].

# Why isn't anyone already doing this?

While my simple idea of keeping a journal did indeed make my work easier, it was in no way anything original. After all, the whole premise of bookkeeping is about, well, keeping books. And keeping a decent journal isn't rocket science either - anyone with pen and paper can do it, and some basic Excel formulas can easily automate most calculations. So I couldn't help but wonder: _Why aren't these guys already doing this?_

Naturally, I started asking people about it. At first, it seemed like incorrect requests, e.g. requests which assumed there was budget left when there wasn't, were not a problem that anyone had actually had to deal with before, therefore nobody bothered to keep a proper journal. This sounded slightly alarming to me, but I could imagine it being an example of an _if it ain't broke, don't fix it_ mindset. But then I started asking people outside my immediate vicinity, especially people closer to the front lines (that is, the IT guys who actually negotiated and purchased various software and hardware for the company), and I found out that those people _were_ keeping journals, or at least something similar to that. The problem was that each team was doing more or less their own thing, and there was neither any incentive for people to unify their methods, nor any department-wide or company-wide requirement for a standardized way of recording data.

And then one day, one of my colleagues just randomly let out a sigh.

> I wish we could just put the budget item numbers into Accounting's system and get them included in the data exports. That way we could just make a pivot table by budget item number and immediately get a bird's eye view of the whole budget situation...

I was flabbergasted. While I myself hadn't thought of this at the time, it made perfect sense. If people could just record some extra metadata with each transaction, nobody would need to keep a dedicated journal. The exports from the general ledger would be functionally equivalent to that. Just imagine getting a CSV file or Excel table from Accounting that looks like this:

| Date | Department | Account | Amount | Budget Item |
|-----|----|---|--:|---|
| 2026-01-01 | IT | Repairs and Maintenance | $10,000 | B-00001 |
| 2026-01-02 | IT | Repairs and Maintenance | $5,000 | B-00001 |

In reality, Accounting was exporting data that looked like this:

| Date | Department | Account | Amount |
|-----|----|---|--:|---|
| 2026-01-01 | IT | Repairs and Maintenance | $10,000 |
| 2026-01-02 | IT | Repairs and Maintenance | $5,000 |

The result of this was that it became impossible to map actual expenses to the budget data. So people had to either keep their own journal, effectively duplicating part of the work done by Accounting, or just hope that there are no problems (and scramble to figure them out otherwise). The exact reasons why accounting wasn't attaching budget item numbers to the transaction data are something that does warrant a discussion of its own. That being said, in this post I'd like to focus on the managerial accounting part, so I will leave that discussion for another time.

The point I wanted to make with this story is about the nature of transaction data itself. Your everyday run-of-the-mill accounting people worry mostly about producing correct IR statements. Their job is to label each transaction with the correct accounts, so that the company pays the correct amount of taxes and gives investors an accurate idea about its financials. However, when it comes to actually running the company, the focus of interest may no longer be on whether something is considered a telecommunications expense or a utilities expense. Instead, the focus may be on whether that expense was budgeted or not. Or whether that expense arose due to project X or project Y. In order to answer such questions, someone, at some point, has to label each transaction. Those contract fees we paid for setting up 100 new servers in the basement? Someone has to declare that this was part of the budget for project X. The only question is whether such labelling is done inside the company-wide accounting system, or the spreadsheet that Alice hacked on her own PC for convenience.

## Financial data defines the business

About 4 months into the job, I was tasked with figuring out how much our company spends on tech as a whole, along with possible ways to ~~cut costs~~ _optimize_ that.

Okay, that may have been a bit of an overstatement. I was part of a team, that was working on a project, which was about calculating ROIs for the various things going on in the tech departments and then figuring out what is worth doing and what isn't. This project had been going on for quite a while, and it had become standard practice to produce a monthly or quarterly report that showed the total tech expenses, broken down in a few different ways. Originally it had been my boss who produced the reports, but since I was the passionate new guy on the team, this time my boss decided to let me have a go at calculating everything.

This is the point where I'd like to tell you about all the corporate hoops I had to jump through in order to figure out what "total tech cost" even means, and then jump through even more hoops to make sense of data that had its own problems. I believe in learning by example, and I really would have liked it if there was someone to tell me their experience with how these problems arise and how to deal with them back when I was working that job. Unfortunately, such details are not something I can discuss in a blog post. I can, however, talk about the general lessons I learned throughout my endeavours, albeit in a somewhat abstract way. So forgive me if the next few paragraphs come off somewhat handwavy, but keep in mind that the ideas arise from some very real problems I faced.

<div style="display: flex; flex-direction: column; align-items: center;">
<hr style="margin: 20px 20px 30px 20px; width: 200px;" />
</div>

Let's say you're the head of IT at your company. Up until now your company only ever provisioned Windows PCs, but after months of relentless pushing from developers, it was finally decided that you are going to support Macbooks as well. Dubbed _Project Newton_[^newton], your job is to make it so that 6 months from now any developer can request a Macbook and get one provisioned within a week or so, without them becoming an immediate security liability. Sounds good, right? Let's also suppose that three months later you get invited to a meeting where some people from _very reputable companies_ manage to convince your boss that all projects must have a clearly defined and strictly monitored ROI, and all projects with negative ROI will be abandoned. Naturally, your boss immediately tasks you, along with a few guys from finance, with figuring the ROI for Project Newton and a way to consistently monitor it. Oh, and the deadline is 2 weeks from now.

Unless you foresaw this happening and already started recording all expenses for Project Newton, you might be in a bit of trouble. If your department only has a big list of uncategorized expenses, now you're forced to essentially label all of them. Depending on exactly how much data you have, labelling everything may or may not be feasible to finish in 2 weeks, but at least you know it will give you an _investment_ figure. On the other hand - how do you even define the _return_? How do you even _define_ how much money will the company save if developers used Macbooks instead of Windows PCs?

While I'm not exactly sure how to answer this question myself[^measure], I'd like to sidestep the issue and shift your focus towards a more fundamental issue. That is, you cannot analyze data which you do not have. In the case of expense for Project Newton - if you hadn't foreseen you would need the data later, you would essentially be forced to generate it (i.e. put labels on all your transactions) when that need arose. This _might_ be feasible to do for the last three months' worth of transactions. But what if you had to do it for the whole year? What if it was multiple years? What if you had to do the same thing, but for people's work hours? What if, God forbid, your boss asked you how many total hours were spent planning for Project Newton? And again, even if you could deal with all of these issues, you still have the returns problem - unless you already have a way of measuring "developer productivity" that is already established, good luck calculating the projected savings from using Macbooks.

Now obviously we can go down this rabbit hole for a long time. There's always going to be something that you didn't think about until it was actually necessary. That's just how life works. But that's also part of the point I'm trying to make here. _You can only record what you foresee to be worth recording_. In other words - you only record what you care about. What you don't care about, by that very definition, is the things that you don't record. Your time sheet doesn't have a column for "cups of coffee consumed" because your company doesn't care about that[^coffee]. But the real insight comes you flip this idea around and realize that the things companies bother to measure are precisely the things they care about. 

This insight was probably the most important lesson that working as a financial analyst taught me. Once I learned how to read the metrics, I really started seeing the forest for the trees and reading between the lines when people spoke. A lot of the time people would be talking about ROIs, and projects, and departments, and technical costs, and whatnot, but at the end of the day, they would act in ways which maximize (or otherwise give them an advantage on) _the stuff that was actively being measured_. I say _actively_, because some metrics exist either as an irrelevant side-effect of something or possibly just to check off some box somewhere. On the other hand, active measures get, well, acted upon. An easy example is working hours - if you suddenly started clocking only 2 hours a day instead of 8, you can very confidently expect your boss to do something about it. In this sense, identifying the active measures in my company was eye-opening - I could suddenly understand a lot more about how the business was being run, and more importantly _why_.

Whatsmore, almost as if it was actual physics underneath it all, whole departments and organizations would line up almost perfectly with how things are measured. In the company we would have many different people of many different titles, working on many different projects, having many different responsibilities. Yet, if you looked at it the right way there was almost always the same underlying structure to it. Person A expects person B (and their entire department) to do X, measured on Y. In the software world there's this thing called [Conway's law](https://en.wikipedia.org/wiki/Conway%27s_law), that states:

> Organizations which design systems are constrained to produce designs which are copies of the communication structures of these organizations.

My job as a financial analyst made me realize that this principle applies just as well to the finance world. The data we collect and the labels we give to expenses _define_ how the business is being run. The decision to label an expense as being owned by a given department (rather than, say, a _project_) is in itself a declaration that the company's activities are organized around departments. The decision to calculate proft per department (instead of, say, ROI per project) is in itself a declaration that the company is a conglomerate of self-contained businesses which, while possibly intertwined with each other, are ultimately responsible for their own growth and profitability. In simple terms - financial data defines the business.

## Beyond traditional accounting

Up until now I focused the discussion mostly on the practical lessons I learned from the problems I faced on the job. In this final section however, I'd like to talk a little bit about the theoretical beauty of accounting in general[^authority].

In the previous sections, I discussed how running a company sometimes requires measuring things differently than the way it's required in IR statements and tax codes. When I first realized this, I immediately asked myself a question - then how come the textbooks assume use more or less the same chart of accounts for all companies? Is there some way of organizing expenses that is fundamentally better than everything else?

After quite a bit of pondering on this question, I realized that the answer is no. I'm not entirely sure about how it evolved, but I do believe the common structure of most charts of accounts is a result of the public (and possibly government) just happening to show a particular interest at a particular time towards, say, telecommunication expenses, contract fees and so on.

A more interesting idea arises when you start thinking about mixing different ways of categorizing expenses. For example, a CEO might be interested of having an expense breakdown by department, like so:

```
Expenses
    IT Department
        Software Team       $   5,000,000
        Hardware Team       $   5,000,000
    Marketing Department
        SNS Team            $   2,000,000
        Ad Team             $   3,000,000
    Accounting Department   $   3,000,000
    Sales Department        $   8,000,000
    Other                   $   1,000,000
-----------------------------------------
Total                       $  27,000,000
```

In such a scenario, Accounting will need to effectively maintain two different account trees - one for the standard IR statements and one for the department breakdown.

Needless to say, in practice one could have many different people wishing to view the data through the lens of many different account trees. On the other hand, this also means that you would need to add a new label to all transactions for every type of account tree that you maintain. This can quickly get out of hand, where expensing a simple lunch with coworkers requires you to spend half a day filling out overcomplicated forms[^expensing]. This does, however, lead to an interesting problem: **What's the minimum amount of information you need to record per expense, while retaining the ability to aggregate based on every criteria you have?**

Consider two different receipts - one for a lunch with coworkers and one for software licensing fees, both covered by the IT department. If you only cared about the department account tree, you could just record both as an "IT Department expense" and be done with it.

| Department | Amount  |
|---|---:|
| IT Department | $ 200 |
| IT Department | $ 200,000 |

However if the company's IR statement makes a distinction between employee welfare and licensing costs, then you would need to record both the department name _and_ the expense category.

| Department | Category | Amount  |
|---|---|---:|
| IT Department | Employee Welfare | $ 200 |
| IT Department | Licensing Costs | $ 200,000 |

Notice how in the first case it is impossible to differentiate between the two expenses unless you have additional data stored somewhere. All you can really say is that the IT department has spent $200,200 on _something_. On the other hand, in the latter case you can say that IT spent $200 and $200,000 respectively on _separate things_, which are possible to distinguish individually (by looking at the Category column).

In the department breakdown earlier we also distinguished between different teams. IT department has the Software and Hardware team, so we should store that in our database as well. Suppose that the team lunch is covered by the Hardware team and the licensing costs by the Software team.

| Department | Team | Category | Amount  |
|---|---|---|---:|
| IT | Hardware Team | Employee Welfare | $ 200 |
| IT | Software Team | Licensing Costs | $ 200,000 |

Now hold on a minute. A team can only be part of one department[^team-tree], and our org chart already has this information stored. Wouldn't it be nice if we stored only the team name in the accounting database, then later used the org chart data to get the department name when doing analysis?

| Team | Category | Amount  |
|---|---|---:|
| Hardware Team | Employee Welfare | $ 200 |
| Software Team | Licensing Costs | $ 200,000 |

In the software world, these kinds of tricks are often called performance trade-offs. Here, we reduced the amount of data we store (that is, we skipped the Department column) at the cost of having to manually reference the department during analysis later on. This doesn't sound like much, but if you consider that your employees submit many expense forms every day, removing even a single field from the form could be significant. Granted, the Department field example is probably something that most companies already automate, but it does illustrate the point.

The interesting part comes when you consider what happens if you suddenly need information that you never recorded before. Suppose that some of the licensing costs are to be counted towards Project Newton, but the team lunch had nothing to do with it. How do you make _that_ distinction? In other words, how do you come up with a table that looks like this?

| Team | Category | Project | Amount  |
|---|---|---|---:|
| Hardware Team | Employee Welfare | N/A | $ 200 |
| Software Team | Licensing Costs | N/A | $ 100,000 |
| Software Team | Licensing Costs | Newton | $ 100,000 |

While I was thining about this, I realized that fundamentally this is a problem about giving an identity to money (in our case _expenses_ in particular). Adding a bunch of fields to our transaction is fundamentally a way of splitting expenses into _boxes_ (rows) which can later be aggregated to give us an overview of the bigger picture. This is easy if we already know how we are going to organize those boxes, but sometimes we run into a situation where we need to open some of the boxes and split their contents more granularly. So how do we decide how small the smallest box should be?

This is where the idea of a trade-off I mentioned earlier starts to shine. Just like how we were able to shave off the Department field once we had the Team field, what if it were possible to have a way of uniquely identifying each individual transaction (along with all the context associated with it), as long as we were willing to spend some time on it? Up until now, I was assuming that accounting data is stored as well-structured rows in a database. But what if you stored the stuff that is _not_ well-structured? For every transaction, you could store the (scanned) physical receipts, maybe some rough text notes about why it was initiated, possibly including references to existing projects, departments, or anything else really? If you had all that data stored, even if you couldn't instantly figure out whether a transaction is to be counted towards Project Newton or not, maybe reading through the notes would be enough to deduce that.

I realize I'm making this sound somewhat more genius than it actually is, but the point I'm trying to make is ultimately about _identity_. Imagine a table like this:

| ID | Amount |
|---|---:|
| 001 | $ 200 |
| 002 | $ 100,000 |
| 003 | $ 100,000 |

As long as each expense has an identity, you can tie arbitrary information to that expense. Some of that is information that you can only realistically store as-is &mdash; e.g. the raw receipts. But some information &mdash; e.g. the department name &mdash; might be stuff that you _don't_ need to store and can instead infer from the surrounding context and/or other information sources. This inference can be done either automatically (system looks up department name from team name) or manually (you read through the receipt and infer that it was for Project Newton), but nonetheless it is still possible. In fact, the more technology advances, the more such inference becomes automatable[^auto-infer].

Thinking about it this way, it seems to me more and more that accounting, or at least this aspect of it, is really just the art of keeping track of the identity of all the pieces that ultimately get combined into a single homogeneous pile. Humanity came up with the concept of commodity precisely because of the convenience of commonness, yet at the same time we ended up inventing an entire industry of the art of destructuring that commonness into meaningful pieces. One could certainly argue about the irony of it, but still I say:

_Isn't this beautiful?_

---

[^exam]: In February 2025 I passed the 日商簿記 2 級 exam, which is a Japanese exam that covers basic to intermediate accounting skills.
[^cloudcosts]: For all my DevOps comrades out there - basically the on-prem and public cloud costs.
[^techdomain]: An example of a technical issue would be a system which allows read access _only_ to people part of the approval chain. An example of a domain issue would be an unclear definition of what it means for a financial anlayst to approve a budget (and what responsibilities such approval implies).
[^analogy]: For those of you used to standard terminology, consider the following analogy. Imagine the budget items as assets, budget increase as income and budget deduction as expense. I basically had one income account, one expense account, and a few hundred asset accounts.
[^hledger]: In practice, I was using a tool called [hledger](https://hledger.org/). I won't go into the specifics of how it works, but think of it like a combination of Word and Calculator - I write my journal as simple text, then it automatically ensures each transaction is balanced and shows the latest balance for each account.
[^newton]: As is customary in corporate, big projects need memorable names that immediately convey the context of the conversation during meetings. Newton got hit by an apple and became one of the greatest innovators in the history of math - isn't this a perfect name for our project? <span style="font-size: 5px;">/s</span>
[^measure]: I've seen people recommend the book [How to Measure Anthing](https://www.amazon.com/dp/1118539273) by Douglas Hubbard about this subject. I haven't read it yet but it is on my to-read list.
[^loc]: I don't believe this to be a reliable metric whatsoever.
[^coffee]: ...until something happens that ends up limiting the world supply of coffee and suddenly companies start charging you for using the coffee machine or something.
[^authority]: As a person who is entirely self-taught when it comes to accounting, I'd like to ask that you read the rest of this section with a healthy dose of skepticism in mind. I have thought really hard about these ideas and I do like to believe they're accurate, but I haven't had enough education or experience to claim any level of credibility for them. Therefore if you spot any problems - do not hesitate to let me know!
[^expensing]: Open up your company's expensing system and take a look - how many different fields do you need to fill in before you can submit?
[^team-tree]: For the sake of argument, let's assume that this is the case in our fictional company.
[^auto-infer]: Come to think of it, reading through a bunch of receipts and figuring out if they were related to a particular project or not sounds like the kind of task recent AI would be extremely efficient at.