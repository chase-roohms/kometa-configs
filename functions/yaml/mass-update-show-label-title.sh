#!/bin/bash

# Mass update label_title field for all shows in show-metadata.yml
# Usage: mass-update-show-label-title.sh <api_key> [metadata_file]

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <api_key> [metadata_file]"
    echo "  api_key: TVDb API key"
    echo "  metadata_file: Path to metadata file (default: show-metadata.yml)"
    exit 1
fi

api_key="$1"
metadata_file="${2:-show-metadata.yml}"

# Validate that metadata_file exists
if [ ! -f "$metadata_file" ]; then
    echo "Error: metadata_file '$metadata_file' does not exist."
    exit 1
fi

# Get the directory where this script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
get_auth_token_script="$script_dir/../tvdb/get_auth_token.sh"
get_english_show_title_script="$script_dir/../tvdb/get_english_show_title.sh"

# Validate that required scripts exist
if [ ! -f "$get_auth_token_script" ]; then
    echo "Error: get_auth_token.sh not found at '$get_auth_token_script'"
    exit 1
fi

if [ ! -f "$get_english_show_title_script" ]; then
    echo "Error: get_english_show_title.sh not found at '$get_english_show_title_script'"
    exit 1
fi

# Get auth token from API key
echo "Getting TVDb auth token..."
auth_token=$(bash "$get_auth_token_script" "$api_key" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$auth_token" ]; then
    echo "Error: Failed to get auth token from TVDb API"
    exit 1
fi

echo "Auth token obtained successfully"
echo ""

# Extract all show IDs from the metadata file
echo "Extracting show IDs from $metadata_file..."
show_ids=$(yq eval '.metadata | keys | .[]' "$metadata_file")

if [ -z "$show_ids" ]; then
    echo "No show IDs found in $metadata_file"
    exit 0
fi

total_shows=$(echo "$show_ids" | wc -l | tr -d ' ')
echo "Found $total_shows shows to process"
echo ""

# Counter for progress tracking
current=0
updated=0
skipped=0
errors=0

# Process each show ID
while IFS= read -r tvdb_id; do
    current=$((current + 1))
    echo "[$current/$total_shows] Processing TVDb ID: $tvdb_id"
    
    # Get English title from TVDb (with trailing year removed)
    series_name=$(bash "$get_english_show_title_script" "$tvdb_id" "$auth_token" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$series_name" ] && [ "$series_name" != "null" ]; then
        # Get current label_title
        current_label_title=$(yq eval ".metadata.$tvdb_id.label_title" "$metadata_file")
        
        if [ "$current_label_title" != "$series_name" ]; then
            echo "  Updating label_title: '$current_label_title' -> '$series_name'"
            
            # Update the label_title field
            yq eval -i ".metadata.$tvdb_id.label_title = \"$series_name\"" "$metadata_file"
            updated=$((updated + 1))
        else
            echo "  Label title already correct: '$series_name'"
            skipped=$((skipped + 1))
        fi
    else
        echo "  Error: Failed to get English title from TVDb"
        errors=$((errors + 1))
    fi
    
    echo ""
    
    # Add a small delay to avoid rate limiting
    sleep 0.25
done <<< "$show_ids"

echo "================================"
echo "Update Summary:"
echo "  Total shows: $total_shows"
echo "  Updated: $updated"
echo "  Skipped (already correct): $skipped"
echo "  Errors: $errors"
echo "================================"

if [ $errors -gt 0 ]; then
    exit 1
fi

exit 0
