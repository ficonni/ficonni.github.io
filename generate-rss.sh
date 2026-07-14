#!/bin/bash

SITE_URL="https://ficonni.github.io"
OUTPUT="rss/feed.xml"
TITLE="ficonni's space"
DESCRIPTION="Personal site, academic notes, and literary thoughts."

mkdir -p rss

cat <<EOF >"$OUTPUT"
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
    <title>$TITLE</title>
    <link>$SITE_URL</link>
    <description>$DESCRIPTION</description>
    <atom:link href="$SITE_URL/$OUTPUT" rel="self" type="application/rss+xml" />
    <lastBuildDate>$(date -R)</lastBuildDate>
EOF

# Extract files linked in index.html to only include referenced pages
get_files() {
  for dir in ./blog ./articles ./academic ./literary; do
    if [ -f "$dir/index.html" ]; then
      grep -oE 'href="[^"]+\.(html|pdf)"' "$dir/index.html" | cut -d'"' -f2 | while read -r link; do
        if [[ "$link" == http* ]] || [[ "$link" == /* ]] || [[ "$link" == ../* ]]; then
          continue
        fi
        file="$dir/$link"
        if [ -f "$file" ]; then
          echo "$file"
        fi
      done
    fi
  done
}

get_files | xargs -I{} stat -c "%Y %n" {} 2>/dev/null | sort -nr | cut -d' ' -f2- | while read -r file; do

  # Extract title strictly using sed (case-insensitive)
  PAGE_TITLE=$(sed -n -e 's/.*<h1> *\(.*\) *<\/h1>.*/\1/Ip' "$file" | head -n 1)

  # Fallback to filename without extension if the title tag is completely missing
  [ -z "$PAGE_TITLE" ] && PAGE_TITLE=$(basename "$file" | sed 's/\.[^.]*$//')

  PUB_DATE=$(date -R -r "$file")
  SLUG="${file#./}"

  cat <<EOF >>"$OUTPUT"
    <item>
        <title>$PAGE_TITLE</title>
        <link>$SITE_URL/$SLUG</link>
        <guid isPermaLink="true">$SITE_URL/$SLUG</guid>
        <pubDate>$PUB_DATE</pubDate>
    </item>
EOF
done

cat <<EOF >>"$OUTPUT"
</channel>
</rss>
EOF
