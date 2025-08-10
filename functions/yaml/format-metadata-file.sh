#!/bin/bash

# Check if a file path is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <file-path>"
    exit 1
fi

METADATA_FILE="$1"

# Check if the file exists
if [ ! -f "$METADATA_FILE" ]; then
    echo "File not found: $METADATA_FILE"
    exit 1
fi

# Single quote the release year
yq -i '(.metadata[] | select(has("release_year") and .release_year != null) | .release_year) style="single"' "$METADATA_FILE"

# Single quote the url_poster if it is empty (personal preference)
yq -i '(.metadata[] | select(has("url_poster") and .url_poster == "") | .url_poster) style="single"' "$METADATA_FILE"

# Single quote the url_poster for any seasons if it is empty (personal preference)
yq -i '(.metadata[] | select(has("seasons")) | .seasons[]? | select(has("url_poster") and .url_poster == "") | .url_poster) style="single"' "$METADATA_FILE"
