#!/bin/bash

# Find all movies or shows that are missing a value for the specific key
# Usage: find-field.sh <key> <type: movie|show|all> <movie_metadata_file> <show_metadata_file>
# Returns: JSON array of matching movie/show metadata

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 <key> <type: movie|show|all> <movie_metadata_file> <show_metadata_file>"
    exit 1
fi

key="$1"
type="$2"
movie_file="$3"
show_file="$4"

# Sanitize key and value to remove dangerous characters
key=$(echo "$key" | tr -cd '[:alnum:]_.')
value=$(echo "$value" | tr -cd '[:alnum:] ._-')

case "$type" in
    movie)
        file="$movie_file"
        ;;
    show)
        file="$show_file"
        ;;
    all)
        file="$movie_file $show_file"
        ;;
    *)
        echo "Invalid type: $type. Must be movie, show, or all."
        exit 1
        ;;
esac

allowed_keys=("label_title" "sort_title" "release_year" "studio" "genre.sync" "url_poster" "audio_language")

if [[ ! " ${allowed_keys[@]} " =~ " ${key} " ]]; then
    echo "Invalid key: $key. Allowed keys are: ${allowed_keys[*]}"
    exit 1
fi

# Find values that are empty strings, empty arrays, or null under $key
yq -o=json '
    .metadata
    | to_entries[]
    | select(
            .value["'"$key"'"] == "" 
            or .value["'"$key"'"] == null 
            or (.value["'"$key"'"] | length == 0)
        )
    | .value + {"txdb_id": .key}
' $file | jq -c
