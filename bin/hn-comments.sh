# macOS version

#KEYWORD='raku'

# 1) timestamps for "last 7 days"
START=$(date -v -7d +%s)
END=$(date +%s)

# 2) fetch matching stories from Algolia
curl -s "https://hn.algolia.com/api/v1/search_by_date?query=raku&tags=comment&numericFilters=created_at_i%3E${START},created_at_i%3C${END}&hitsPerPage=1000" \
  -o hn-comments-raku.json

# 3) extract readable lines
#jq -r '.hits[] | [.created_at, (.title // "<no-title>"), (.url // "https://news.ycombinator.com/item?id=\(.objectID)"), .objectID] | @tsv' \
#  hn-last7-raku.json > hn-last7-raku.tsv

# Extract: creation date, comment text (stripped of HTML), and link to parent
jq -r '
  .hits[] |
  [.created_at,
   (.comment_text // "" | gsub("<[^>]*>"; ""; "g")),  # strip HTML tags
   ("https://news.ycombinator.com/item?id=" + (.parent_id|tostring))
  ] | @tsv
' hn-comments-raku.json > hn-comments-raku.tsv

# 4) search locally with rak
rak --ignorecase '/<|w>'"raku"'<|w>/' hn-comments-raku.tsv
