#!/bin/bash

# Check for exactly 2 arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <title> <type [movie|show]>"
    exit 1
fi

title="$1"
type="$2"

# Validate type
if [[ "$type" != "movie" && "$type" != "show" ]]; then
    echo "Error: type must be either 'movie' or 'show'"
    exit 2
fi

encoded_title="$(echo "$title" | sed -e 's/ /+/g' -e 's/&/%26/g')"
echo "https://theposterdb.com/search?term=${encoded_title}&section=${type}s"
