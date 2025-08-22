#!/bin/bash

# Check for exactly 1 argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tvdb_id>"
    exit 1
fi

tvdb_id="$1"

# Validate TVDB ID (should be a number)
if ! [[ "$tvdb_id" =~ ^[0-9]+$ ]]; then
    echo "Error: tvdb_id must be a number"
    exit 2
fi

# Construct TVDB direct link
echo "https://thetvdb.com/dereferrer/series/${tvdb_id}"