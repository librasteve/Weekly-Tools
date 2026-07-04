# Weekly-Tools

A Raku project with helper scripts for writing the Raku Weekly newsletter.

## Main Scripts

- `bin/weekly-helper.raku` — GitHub issues/PRs + RakuLand new/updated modules
- `bin/weekly-google.raku` — Chrome-driven Google search scrape
- `bin/weekly-comments.raku` — consolidated comment search (HN, Fediverse, Bluesky, Lobsters, Stack Overflow)

## Typical Workflow

All three scripts are run from the project root, appending into one `scum.html`:

```
raku -I. bin/weekly-helper.raku    > scum.html
raku -I. bin/weekly-google.raku   >> scum.html
raku -I. bin/weekly-comments.raku >> scum.html
```

The resulting `scum.html` is then opened, the HTML extracted, and copied into the WordPress editor window.
