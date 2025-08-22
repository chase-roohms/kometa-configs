#!/bin/bash

# Check for exactly 1 argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tmdb_id>"
    exit 1
fi

tmdb_id="$1"

# Validate TMDB ID (should be a number)
if ! [[ "$tmdb_id" =~ ^[0-9]+$ ]]; then
    echo "Error: tmdb_id must be a number"
    exit 2
fi

# Construct TMDB direct link
echo "https://www.themoviedb.org/movie/${tmdb_id}"