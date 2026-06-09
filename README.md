[![Actions Status](https://github.com/librasteve/Weekly-Tools/actions/workflows/test.yml/badge.svg)](https://github.com/librasteve/Weekly-Tools/actions)

NAME
====

Weekly::Tools

SYNOPSIS
========

```
raku -I. bin/weekly-helper.raku    > scum.html
raku -I. bin/google-scrape.raku   >> scum.html
raku -I. bin/comments-search.raku >> scum.html
```

DESCRIPTION
===========

Weekly::Tools - a set of ad hoc "helper" scripts to get the raku weekly written


### Google Comments Search

AppleScript drives real Chrome (with your Google session) to scrape 3 pages of results.
Query: `raku programming language` with `tbs=qdr:w` past-week filter.
Requires: Chrome → View → Developer → Allow JavaScript from Apple Events.
Script: `bin/google-scrape.raku`

### Comments Search

All comment sources consolidated into `bin/comments-search.raku`. Fetches in parallel:

- **HN** — Algolia API, comments mentioning `raku` (word boundary), deduped by story, author nicks resolved via `Weekly::Tools::Nicks`
- **Fediverse** — `mastodon.social` federated tag timeline for `#rakulang` (includes Mastodon, Lemmy, and other ActivityPub platforms)
- **Bluesky** — AppleScript drives Chrome to scrape `bsky.app/search?q=%23rakulang&sort=latest`
- **Lobsters** — scrapes `lobste.rs/search?q=raku&what=comments&order=newest`
- **Stack Overflow** — scrapes `stackoverflow.com/questions/tagged/raku?tab=Newest`

All three filtered to last 7 days. Output has `h3` section headers.


ROADMAP
=======

### Search Integration

### RakuAST Stats
looking back at historic editions rakudoweekly.blog there has been a summary of progress on RakuAST by counting remaining tests to pass - please get the latest stats from GH

### Prompt for missing nick
ie if zef: still in the output
auto follow th GH path


AUTHOR
======

librasteve <librasteve@furnival.net>

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Henley Cloud Consulting Ltd.
Copyright 2026 Stephen Roe.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

