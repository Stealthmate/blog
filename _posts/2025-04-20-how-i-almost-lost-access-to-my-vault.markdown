---
layout: post
title: How I almost lost access to my Vault
date: 2025-04-20
---

* Do not remove this line (it will not be displayed)
{:toc}

> _2025-04-20 11:15. I just regained access to Vault. Everything seems to be intact._

Oh boy, this is gonna be a roller coaster so strap-on.

## A quick backstory

Back in late 2023 I made an account on [Vultr](https://vultr.com/) and started my personal Kubernetes journey. I created a single managed cluster with 2 worker nodes, and ever since then I've been using it to play around with various data in my personal life.

I run a lot of stuff on that cluster --- Vault, ArgoCD, Prometheus, Grafana, Argo Workflows, Ingress-NGINX and so on, and that's only the "off-the-shelf" components. On top of that I have some personal servers/cronjobs that do stuff as well.

## The calm before the storm

On April 17th, I noticed that my ingress controller was not working. A little bit of digging around showed that it was experiencing DNS resolution errors, which is weird because I'm not doing anything DNS-related inside the cluster per-se. I tried deleting one of my nodes in a sort of "see if it works after a restart" fashion, but that didn't work. Eventually I opened a support ticket and it turned out that there was some trouble happening inside Vultr's service itself. The whole thing was resolved in less than 2 hours, and I managed to get my cluster working again (although I did reboot one of the nodes anyway). This did turn out to be the node that Vault was running on, so I had to manually unseal the Vault afterwards, but everything seemed to be fine. I did get some weird 504 error when unsealing Vault, but it resolved itself on the second try so I continued on with my day.

## Just a normal sunday morning

Today was supposed to be a very normal Sunday. I woke up around 6:00 am, went for a walk, brewed myself a nice coffee and started hacking at one of my Grafana dashboards. Nothing too serious - I was just changing some Postgres tables and their queries inside Grafana. I pushed everything to GitHub, I opened ArgoCD in order to sync the manifests and... I saw a lot of red. A _lot_ of red.

## Vault is down, and it won't go up

Turns out all my [external secret](https://external-secrets.io/latest/) manifests were failing. Ok, no big deal, probably the Vault node got restarted again. I open up [k9s](https://k9scli.io/) and sure thing, Vault is on standby waiting to be unsealed. I put in my unseal keys once again and... 504 gateway timeout. Eh? Try again. Still 504. Oh boy, this can't be good...

I repeated the wohle process a few more times and observed the errors. Vault seemed to be failing at the `restoring leases` phase, and a bit of digging around led me to believe that there might be a lot of expired leases somewhere that are causing something to load too slow (hence the eventual 504 error). Okay, so I need to find those leases and possibly delete them manually.

For my Vault, I use Vultr's object storage as a backend. So I go inside the UI, open the bucket and it seems to be working... normally? Kinda slow, but nothing _too_ serious. And than I tried listing all the objects using [`s3cmd`](https://s3tools.org/s3cmd). And sure thing, I got my 504 error.

```
ERROR: Error parsing xml: Malformed error XML returned from remote server..  ErrorXML: b"<html><body><h1>504 Gateway Time-out</h1>\nThe server didn't respond in time.\n</body></html>\n"
WARNING: Retrying failed request: <redacted> (504 (Gateway Time-out))
```

Okay, maybe Vultr is having problems again? Nope, there's no outage announcement anywhere. I tried looking at the UI again and then I realized it.

**_I was using a versioned bucket._**

Dear reader, do you know what a [versioned bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html) is? It's basically a bucket where nothing ever gets deleted. Nothing. Ever. [^1]

## GETtting the unGETtable

Ok, so I found the problem. Now it was time to look for a solution. And losing my Vault data was kind of a non-option. I don't have anything that important on it per se, but recreating the vault from scratch would take way too much time, which I don't have these days.

Maybe if I could somehow copy the latest versions of all the files in my vault bucket to a new one, I would be able to boot Vault from there and pretend that nothing ever happened. The problem was that getting files out of the current bucket was very nearly impossible.

Now, my dear reader, this is where the experienced professional's sixth sense comes into play. I knew that most S3 services are really key-value stores, even though they look like directory trees on the front. I also suspected that Vultr is probably enumerating all versions for all files with a given prefix, when asked to list something. So my next thought was - what if I tried to download my bucket little by little?

The first key detail here is that the UI seemed to work as an actual tree - that is, it loaded only the direct children of any given path without taking too much time - so I could inspect directories one by one. The second key detail is that Vault didn't (re)write its files all that often, which meant that most of the data inside the bucket had less than 10 versions per file (and the files themselves weren't that many).

I managed to pull most of Vault's data to my PC, but I did get stuck trying to fetch stuff from `sys/expire/id`. Judging from the name, I suspect there were millions of objects here related to stuff that expired months ago (I hadn't rebooted vault since late 2023/early 2024, probably). So I had to give up on that and hope that it won't impact the actual secrets that Vault is storing.

Finally I put everything I managed to salvage into a new bucket, this time with versioning disabled. Then I booted Vault and voila! It unsealed instantly!

And then I tried to login.

## The root token is dead, long live the operator!

Yeah, you guessed it. I couldn't login. Using the [_root token_](https://developer.hashicorp.com/vault/docs/concepts/tokens#root-tokens). Salvation slipped right between my fingers...

At first I tried to find where the root token info is stored in the old bucket, but I had no luck with that. I suspect it is under `sys/token/id`, but that turned out to fail with a 504 error as well, so I had to give up. Fortunately, if you have access to the Vault CLI and the unseal keys, [it is possible to generate a new root token](https://developer.hashicorp.com/vault/docs/troubleshoot/generate-root-token). So after a bit more digging around Stack Overflow and the Vault source code, I finally just gave up and regenerated it. And this time it worked - I could login and see all my old secrets.

## The aftermath

After restoring Vault, I went back into ArgoCD to check if everything is working normally. External secrets were fine, but then I noticed a bunch of other problems as well. Bad manifests which I never fixed and stuff like that. Also I experienced some permissions issues with Vault, which I suspect were a result of me not being able to copy all of the files from the old bucket. Fortunately enough, reconfiguring permissions was easy (thank you Val from 2023, for encoding everything into [Terraform](https://developer.hashicorp.com/terraform)!).

Anyway, all of this took a total of 4 or 5 hours, if my memory serves me correct. My entire morning and lunch went down the rabbit hole. I'm a bit bummed that I spent a quarter of my weekend dealing with this shit, but oh well, at least I learned something from it.

Time to go get myself a well-deserved ice-cream now. Bye!

---

[^1]: _Maybe S3 or other cloud services provide a way of setting expiration dates for versions, but Vultr doesn't. A versioned bucket in Vultr is basically a permanent object store, until you deleted the bucket itself._

[^2]: _I have this grand dream of writing my own image processing pipeline and/or GUI software, so ideally I'd like to learn libraries which I can rely on in the future. Then again, this is just an experiment, so I shouldn't overthink it either._
