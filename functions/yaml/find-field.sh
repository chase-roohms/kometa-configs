#!/bin/bash

# Find all movies or shows with a specific key equal to some value
# Usage: find-field.sh <key> <value> <type: movie|show|all>
# Returns: JSON array of matching movie/show metadata

if [[ $# -ne 5 ]]; then
    echo "Usage: $0 <key> <value> <type: movie|show|all> <movie_metadata_file> <show_metadata_file>"
    exit 1
fi

key="$1"
value="$2"
type="$3"
movie_file="$4"
show_file="$5"

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

if [[ "$key" != "genre.sync" ]]; then
    yq -o=json '.metadata | to_entries[] | select(.value["'"$key"'"] == "'"$value"'") | .value + {"txdb_id": .key}' $file | jq -s
else
    yq -o=json '.metadata[] | select((."'"$key"'" // []) | (tag == "!!seq" and .[] == "'"$value"'"))' $file | jq -s
fi
