#!/bin/bash

# Mass update label_title field for all movies in movie-metadata.yml
# Usage: mass-update-movie-label-title.sh <access_token> [metadata_file]

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <access_token> [metadata_file]"
    echo "  access_token: TMDb API access token (Bearer token)"
    echo "  metadata_file: Path to metadata file (default: movie-metadata.yml)"
    exit 1
fi

access_token="$1"
metadata_file="${2:-movie-metadata.yml}"

# Validate that metadata_file exists
if [ ! -f "$metadata_file" ]; then
    echo "Error: metadata_file '$metadata_file' does not exist."
    exit 1
fi

# Get the directory where this script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
get_movie_script="$script_dir/../tmdb/get_movie.sh"

# Validate that get_movie.sh exists
if [ ! -f "$get_movie_script" ]; then
    echo "Error: get_movie.sh not found at '$get_movie_script'"
    exit 1
fi

# Extract all movie IDs from the metadata file
echo "Extracting movie IDs from $metadata_file..."
movie_ids=$(yq eval '.metadata | keys | .[]' "$metadata_file")

if [ -z "$movie_ids" ]; then
    echo "No movie IDs found in $metadata_file"
    exit 0
fi

total_movies=$(echo "$movie_ids" | wc -l | tr -d ' ')
echo "Found $total_movies movies to process"
echo ""

# Counter for progress tracking
current=0
updated=0
skipped=0
errors=0

# Process each movie ID
while IFS= read -r tmdb_id; do
    current=$((current + 1))
    echo "[$current/$total_movies] Processing TMDb ID: $tmdb_id"
    
    # Get movie details from TMDb
    movie_data=$(bash "$get_movie_script" "$tmdb_id" "$access_token" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # Extract the title from the movie data
        title=$(echo "$movie_data" | jq -r '.title')
        
        if [ -n "$title" ] && [ "$title" != "null" ]; then
            # Get current label_title
            current_label_title=$(yq eval ".metadata.$tmdb_id.label_title" "$metadata_file")
            
            if [ "$current_label_title" != "$title" ]; then
                echo "  Updating label_title: '$current_label_title' -> '$title'"
                
                # Update the label_title field
                yq eval -i ".metadata.$tmdb_id.label_title = \"$title\"" "$metadata_file"
                updated=$((updated + 1))
            else
                echo "  Label title already correct: '$title'"
                skipped=$((skipped + 1))
            fi
        else
            echo "  Error: Could not extract title from TMDb response"
            errors=$((errors + 1))
        fi
    else
        echo "  Error: Failed to fetch movie data from TMDb"
        errors=$((errors + 1))
    fi
    
    echo ""
    
    # Add a small delay to avoid rate limiting
    sleep 0.25
done <<< "$movie_ids"

echo "================================"
echo "Update Summary:"
echo "  Total movies: $total_movies"
echo "  Updated: $updated"
echo "  Skipped (already correct): $skipped"
echo "  Errors: $errors"
echo "================================"

if [ $errors -gt 0 ]; then
    exit 1
fi

exit 0
