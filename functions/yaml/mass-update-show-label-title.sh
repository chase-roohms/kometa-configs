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
get_show_script="$script_dir/../tvdb/get_show.sh"

# Validate that required scripts exist
if [ ! -f "$get_auth_token_script" ]; then
    echo "Error: get_auth_token.sh not found at '$get_auth_token_script'"
    exit 1
fi

if [ ! -f "$get_show_script" ]; then
    echo "Error: get_show.sh not found at '$get_show_script'"
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
    
    # Get English translation of the series name from TVDb
    response_file=$(mktemp)
    http_code=$(curl -s -w "%{http_code}" -o "$response_file" --request GET \
        --url "https://api4.thetvdb.com/v4/series/$tvdb_id/translations/eng" \
        --header "Authorization: Bearer $auth_token")
    
    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        # Extract the English series name
        series_name=$(jq -r '.data.name' < "$response_file")
        rm -f "$response_file"
        
        if [ -n "$series_name" ] && [ "$series_name" != "null" ]; then
            # Remove year in parentheses at the end of the title (e.g., "Archer (2009)" -> "Archer")
            series_name=$(echo "$series_name" | sed -E 's/ \([0-9]{4}\)$//')
            
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
            echo "  Error: Could not extract English series name from TVDb response"
            errors=$((errors + 1))
        fi
    else
        rm -f "$response_file"
        echo "  Error: Failed to fetch English translation from TVDb (HTTP $http_code)"
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
