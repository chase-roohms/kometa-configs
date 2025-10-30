#!/bin/bash

# Mass update tpdb_search field for all movies in movie-metadata.yml
# Usage: mass-update-tpdb-search.sh <type> [metadata_file]

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <type> [metadata_file]"
    echo "  type: Media type - 'movie' or 'show'"
    echo "  metadata_file: Path to metadata file (default: movie-metadata.yml for movies, show-metadata.yml for shows)"
    exit 1
fi

type="$1"

# Validate type
if [[ "$type" != "movie" && "$type" != "show" ]]; then
    echo "Error: type must be either 'movie' or 'show'"
    exit 1
fi

# Set default metadata file based on type
if [ "$#" -ge 2 ]; then
    metadata_file="$2"
else
    if [[ "$type" == "movie" ]]; then
        metadata_file="movie-metadata.yml"
    else
        metadata_file="show-metadata.yml"
    fi
fi

# Validate that metadata_file exists
if [ ! -f "$metadata_file" ]; then
    echo "Error: metadata_file '$metadata_file' does not exist."
    exit 1
fi

# Get the directory where this script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
get_tpdb_search_script="$script_dir/../media/get-tpdb-search.sh"

# Validate that get-tpdb-search.sh exists
if [ ! -f "$get_tpdb_search_script" ]; then
    echo "Error: get-tpdb-search.sh not found at '$get_tpdb_search_script'"
    exit 1
fi

# Extract all media IDs from the metadata file
echo "Extracting ${type} IDs from $metadata_file..."
media_ids=$(yq eval '.metadata | keys | .[]' "$metadata_file")

if [ -z "$media_ids" ]; then
    echo "No ${type} IDs found in $metadata_file"
    exit 0
fi

total_items=$(echo "$media_ids" | wc -l | tr -d ' ')
echo "Found $total_items ${type}s to process"
echo ""

# Counter for progress tracking
current=0
updated=0
skipped=0
errors=0

# Process each media ID
while IFS= read -r media_id; do
    current=$((current + 1))
    
    if [[ "$type" == "movie" ]]; then
        echo "[$current/$total_items] Processing TMDb ID: $media_id"
    else
        echo "[$current/$total_items] Processing TVDb ID: $media_id"
    fi
    
    # Get current label_title
    label_title=$(yq eval ".metadata.$media_id.label_title" "$metadata_file")
    
    if [ -z "$label_title" ] || [ "$label_title" == "null" ]; then
        echo "  Error: No label_title found for ID $media_id"
        errors=$((errors + 1))
        echo ""
        continue
    fi
    
    echo "  Label Title: '$label_title'"
    
    # Generate tpdb_search URL using the function
    new_tpdb_search=$(bash "$get_tpdb_search_script" "$label_title" "$type")
    
    if [ $? -eq 0 ] && [ -n "$new_tpdb_search" ]; then
        # Get current tpdb_search
        current_tpdb_search=$(yq eval ".metadata.$media_id.tpdb_search" "$metadata_file")
        
        if [ "$current_tpdb_search" != "$new_tpdb_search" ]; then
            echo "  Updating tpdb_search:"
            echo "    Old: '$current_tpdb_search'"
            echo "    New: '$new_tpdb_search'"
            
            # Update the tpdb_search field
            yq eval -i ".metadata.$media_id.tpdb_search = \"$new_tpdb_search\"" "$metadata_file"
            updated=$((updated + 1))
        else
            echo "  TPDB search already correct"
            skipped=$((skipped + 1))
        fi
    else
        echo "  Error: Failed to generate TPDB search URL"
        errors=$((errors + 1))
    fi
    
    echo ""
done <<< "$media_ids"

echo "================================"
echo "Update Summary:"
echo "  Total ${type}s: $total_items"
echo "  Updated: $updated"
echo "  Skipped (already correct): $skipped"
echo "  Errors: $errors"
echo "================================"

if [ $errors -gt 0 ]; then
    exit 1
fi

exit 0
