#!/bin/bash

# Check for exactly 1 argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <title>"
    exit 1
fi

title="$1"

# Convert to lowercase for comparison
lower_title="$(echo "$title" | tr '[:upper:]' '[:lower:]')"

# Save default sort title
sort_title="$title"

# Remove leading articles
for article in "a " "an " "the "; do
    if [[ "$lower_title" == "$article"* ]]; then
        sort_title="${title:${#article}}"
        break
    fi
done

result="$(echo "$sort_title" | iconv -f UTF-8 -t ASCII//TRANSLIT -c 2>/dev/null)"
# Trim trailing whitespace (spaces, tabs, newlines)
echo "$result" | sed 's/[[:space:]]*$//'
