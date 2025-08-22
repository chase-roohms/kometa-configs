#!/bin/bash

# Check for exactly 3 arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <title> <release_year> <type [movie|show]>"
    exit 1
fi

title="$1"
release_year="$2"
type="$3"

# Validate type
if [[ "$type" != "movie" && "$type" != "show" ]]; then
    echo "Error: type must be either 'movie' or 'show'"
    exit 2
fi

# Validate release year (basic check for 4-digit number)
if ! [[ "$release_year" =~ ^[0-9]{4}$ ]]; then
    echo "Error: release_year must be a 4-digit number"
    exit 3
fi

# Encode title for URL (replace spaces with + and encode special characters)
encoded_title="$(echo "$title" | sed -e 's/ /+/g' -e 's/&/%26/g')"

# Construct Google search URL
echo "https://www.google.com/search?q=${encoded_title}+${release_year}+${type}"