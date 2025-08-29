#!/bin/bash

if [ "$#" -ne 9 ]; then
    echo "Usage: $0 <type> <txdb_id> <title> <release_year> <url_poster> <genres [json array|comma spaced string]> <seasons [bash array|comma spaced string]> <studio> <metadata_file>"
    exit 1
fi

type="$1"
txdb_id="$2"
title="$3"
sort_title="$(bash functions/media/get-sort-title.sh "$title")"
release_year="$4"
url_poster="$5"
tpdb_search="$(bash functions/media/get-tpdb-search.sh "$title" "$type")"
genres="$6"
seasons="$7"
studio="$8"
metadata_file="$9"

# Validate that txdb_id contains only numbers
if ! [[ "$txdb_id" =~ ^[0-9]+$ ]]; then
    echo "Error: txdb_id must contain only numbers."
    exit 1
fi
# Validate that type is either "movie" or "show"
if [[ "$type" != "movie" && "$type" != "show" ]]; then
    echo "Error: type must be either 'movie' or 'show'."
    exit 1
fi
# Validate that release_year is a valid year (4 digits)
if ! [[ "$release_year" =~ ^[0-9]{4}$ ]]; then
    echo "Error: release_year must be a valid year (4 digits)."
    exit 1
fi
# Validate that metadata_file is a valid file
if [ ! -f "$metadata_file" ]; then
    echo "Error: metadata_file must be a valid file."
    exit 1
fi
# Check if genres is a valid JSON array, otherwise try to convert comma-separated string to JSON array
if echo "$genres" | jq -e . >/dev/null 2>&1; then
    genres_json="$(echo "$genres" | jq -s -c .[])"
else
    # Convert comma-separated string to JSON array (compact, no newlines)
    IFS=',' read -ra genre_array <<< "$genres"
    genres_json=$(printf '%s\n' "${genre_array[@]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -R . | jq -s -c .)
fi

# Check if seasons is a valid JSON array otherwise try to convert comma-separated string to JSON array
if [[ $type == "show" ]]; then
    if [[ "$seasons" =~ ^[0-9]+$ ]]; then
        # Just one season number
        seasons_json="[$seasons]"
    elif echo "$seasons" | jq -e . >/dev/null 2>&1; then
        # JSON array
        seasons_json="$(echo "$seasons" | jq -s -c .[])"
    else
        # Comma seperated string
        IFS=',' read -ra season_array <<< "$seasons"
        seasons_json=$(printf '%s\n' "${season_array[@]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -R 'tonumber' | jq -s -c .)
    fi
fi

# Log the media item being added
echo "Adding media item:"
echo "  Media Type: $type"
if [[ $type == "show" ]]; then
    echo "  TVDb ID: $txdb_id"
else
    echo "  TMDb ID: $txdb_id"
fi
echo "  Title: $title"
echo "  Sort Title: $sort_title"
echo "  Release Year: $release_year"
echo "  URL Poster: $url_poster"
echo "  TPDB Search: $tpdb_search"
echo "  Genres: $genres_json"
if [[ -n "$studio" ]]; then
    echo "  Studio: $studio"
fi
if [[ $type == "show" ]]; then
    echo "  Seasons: $seasons_json"
fi

# Add the media item to the metadata file
if [[ $(yq ".metadata.$txdb_id" "$metadata_file") == null ]]; then
    echo "Media does not exist, adding"
    if [[ -n "$studio" ]]; then
        yq -i '.metadata += {'"$txdb_id"': {"label_title": "'"$title"'", "sort_title": "'"$sort_title"'", "release_year": "'"$release_year"'", "url_poster": "'"$url_poster"'", "tpdb_search": "'"$tpdb_search"'", "studio": "'"$studio"'", "genre.sync": '"$genres_json"'}}' "$metadata_file"
    else
        yq -i '.metadata += {'"$txdb_id"': {"label_title": "'"$title"'", "sort_title": "'"$sort_title"'", "release_year": "'"$release_year"'", "url_poster": "'"$url_poster"'", "tpdb_search": "'"$tpdb_search"'", "genre.sync": '"$genres_json"'}}' "$metadata_file"
    fi
fi
if [[ $type == "show" ]]; then
    echo "$seasons_json" | jq -c '.[]' | while read -r season; do
        if [[ $(yq ".metadata.$txdb_id.seasons.$season" "$metadata_file") == null ]]; then
            echo "Season $season does not exist, adding"
            yq -i '.metadata.'"$txdb_id"'.seasons += {'"$season"': {"url_poster": ""}}' "$metadata_file"
        fi
    done
fi
