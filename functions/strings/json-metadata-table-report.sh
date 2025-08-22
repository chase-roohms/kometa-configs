#!/bin/bash

# Create a markdown table from JSON metadata output from find-missing.sh
# Usage: json-metadata-to-table.sh <json_metadata>
# The JSON metadata should be the output from find-missing.sh function

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <json_metadata>"
    echo "Expected input: JSON metadata from find-missing.sh function"
    exit 1
fi

json_metadata="$1"
if [[ -z "$json_metadata" ]]; then
    echo "Warning: No JSON metadata provided." >&2
    exit 0
fi

# Function to determine if ID is TMDB or TVDB based on context/length
# This is a heuristic - you may need to adjust based on your data
get_db_link() {
    local id="$1"
    local type="$2"
    
    # For shows, typically use TVDB; for movies, typically use TMDB
    # You may need to adjust this logic based on your specific setup
    if [[ "$type" == "show" ]]; then
        bash functions/media/get-tvdb-link.sh "$id"
    else
        bash functions/media/get-tmdb-link.sh "$id"
    fi
}

# Function to determine media type based on available fields or context
# You may need to adjust this logic based on your metadata structure
determine_type() {
    local json_item="$1"
    
    # Check if it has seasons (indicates show)
    if echo "$json_item" | jq -e '.seasons' >/dev/null 2>&1; then
        echo "show"
    else
        echo "movie"
    fi
}

# Print markdown table header
echo "| TXDB ID | Title | Release Year | TPDB Search | Google Search |"
echo "|---------|-------|--------------|-------------|---------------|"

# Process each JSON object
echo "$json_metadata" | while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # Extract fields from JSON
        txdb_id=$(echo "$line" | jq -r '.txdb_id // empty')
        title=$(echo "$line" | jq -r '.label_title // empty')
        release_year=$(echo "$line" | jq -r '.release_year // empty')
        
        # Skip if essential fields are missing
        if [[ -z "$txdb_id" || -z "$title" || -z "$release_year" ]]; then
            continue
        fi
        
        # Determine media type
        media_type=$(determine_type "$line")
        
        # Generate links
        db_link=$(get_db_link "$txdb_id" "$media_type")
        tpdb_link=$(bash functions/media/get-tpdb-search.sh "$title" "$media_type")
        google_link=$(bash functions/media/get-google-search.sh "$title" "$release_year" "$media_type")

        # Create markdown table row
        printf "| [%s](%s) | %s | %s | [TPDb](%s) | [Google](%s) |\n" \
            "$txdb_id" "$db_link" "$title" "$release_year" "$tpdb_link" "$google_link"
    fi
done
