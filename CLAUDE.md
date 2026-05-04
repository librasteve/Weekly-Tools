# Weekly-Tools

A Raku project with helper scripts for writing the Raku Weekly newsletter.

## Main Scripts

- `bin/gh-prs2.raku` — GitHub PRs helper
- `bin/weekly-helper.raku` — weekly helper script

## Typical Workflow

Both scripts are run from the project root with:

```
raku -I. bin/gh-prs2.raku > scum.html
raku -I. bin/weekly-helper.raku > scum.html
```

The resulting `scum.html` is then opened, the HTML extracted, and copied into the WordPress editor window.
