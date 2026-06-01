[![Actions Status](https://github.com/librasteve/Weekly-Tools/actions/workflows/test.yml/badge.svg)](https://github.com/librasteve/Weekly-Tools/actions)

NAME
====

Weekly::Tools

SYNOPSIS
========

```
raku -I. bin/weekly-helper.raku
raku -I. bin/google-scrape.raku
raku -I. bin/hn-search.raku
raku -I. bin/lobsters-search.raku
raku -I. bin/stackoverflow-search.raku
raku -I. bin/mastodon-search.raku
raku -I. bin/bsky-search.raku
```

DESCRIPTION
===========

Weekly::Tools - a set of ad hoc "helper" scripts to get the raku weekly written


### Google Comments Search

AppleScript drives real Chrome (with your Google session) to scrape 3 pages of results.
Query: `raku programming language` with `tbs=qdr:w` past-week filter.
Requires: Chrome → View → Developer → Allow JavaScript from Apple Events.
Script: `bin/google-scrape.raku`

### HN Comments Search

Queries the Algolia HN API for comments mentioning `raku` (word boundary) in the past 7 days.
Deduplicates by story, resolves author handles via `Weekly::Tools::Nicks`, outputs linked snippets.
Script: `bin/hn-search.raku`

### Lobsters Comments Search

Scrapes `lobste.rs/search?q=raku&what=comments&order=newest`, filters to past 7 days.
Resolves author handles via `Weekly::Tools::Nicks`.
Script: `bin/lobsters-search.raku`

### Stack Overflow Questions

Scrapes `stackoverflow.com/questions/tagged/raku?tab=Newest`, filters to past 7 days.
Script: `bin/stackoverflow-search.raku`

### Bluesky, Mastodon Comments

AppleScript drives real Chrome to scrape Bluesky search results for `#rakulang` (Latest tab), filtered to last 7 days.
Script: `bin/bsky-search.raku` [may need manual login]

Fetches Mastodon public tag timeline for `#rakulang` via the mastodon.social REST API, filtered to last 7 days.
Script: `bin/mastodon-search.raku`


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

