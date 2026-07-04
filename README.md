[![Actions Status](https://github.com/librasteve/Weekly-Tools/actions/workflows/test.yml/badge.svg)](https://github.com/librasteve/Weekly-Tools/actions)

NAME
====

Weekly::Tools

SYNOPSIS
========

```
raku -I. bin/weekly-helper.raku   > scum.html
raku -I. bin/weekly-google.raku  >> scum.html
raku -I. bin/weekly-comments.raku >> scum.html
```

DESCRIPTION
===========

Weekly::Tools - a set of ad hoc "helper" scripts to get the raku weekly written

### Weekly Helper

`bin/weekly-helper.raku` renders two sections:

- **GitHub** — new Problem Solving issues and Doc & Web pull requests from the last week (`Weekly::Tools::GitHub`)
- **RakuLand** — new and updated modules from `raku.land/recent`, determined by diffing today's module-name snapshot against the nearest one from ~7 days ago (`Weekly::Tools::Dists`, `Weekly::Tools::RakuLand`). Snapshots are cached under `data/dists-YYYY-MM-DD`. If the dist snapshot can't be fetched, the RakuLand section is skipped rather than failing the whole run.

### Google Comments Search

AppleScript drives real Chrome (with your Google session) to scrape 3 pages of results.
Query: `raku programming language` with `tbs=qdr:w` past-week filter.
Requires: Chrome → View → Developer → Allow JavaScript from Apple Events.
Script: `bin/weekly-google.raku`

### Comments Search

All comment sources consolidated into `bin/weekly-comments.raku`. Fetches in parallel:

- **HN** — Algolia API, comments mentioning `raku` (word boundary), deduped by story, author nicks resolved via `Weekly::Tools::Nicks`
- **Fediverse** — `mastodon.social` federated tag timeline for `#rakulang` (includes Mastodon, Lemmy, and other ActivityPub platforms)
- **Bluesky** — AppleScript drives Chrome to scrape `bsky.app/search?q=%23rakulang&sort=latest`
- **Lobsters** — scrapes `lobste.rs/search?q=raku&what=comments&order=newest`
- **Stack Overflow** — scrapes `stackoverflow.com/questions/tagged/raku?tab=Newest`

All five filtered to last 7 days. Output has an `h3` section header.


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

