#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <json_array> <output_md_file>"
    exit 1
fi

json_array="$1"
output_md_file="$2"

# Temporary files for storing intermediate results
temp_movie_file=$(mktemp)
temp_show_file=$(mktemp)

# Create table headers
echo "| TMDB | Title | Release Year | Poster | Genres |" >> "$temp_movie_file"
echo "|------|-------|--------------|--------|--------|" >> "$temp_movie_file"

echo "| TVDB | Title | Release Year | Poster | Genres | Seasons |" >> "$temp_show_file"
echo "|------|-------|--------------|--------|--------|---------|" >> "$temp_show_file"

# Function to convert a JSON array to an HTML list
function array_to_html_list() {
    local json_array="$1"
    local html_list="<ul>"
    while read -r item; do
        html_list+="<li>$item</li>"
    done < <(echo "$json_array" | jq -r '.[]')
    html_list+="</ul>"
    echo "$html_list"
}

# Function to convert a JSON array of seasons to a JSON array of Markdown links
function seasons_to_md_links() {
    local seasons_json="$1"
    local output=""
    local first=1
    while read -r season; do
        season_number=$(echo "$season" | jq -r .season_number)
        if [[ "$season_number" -eq 0 ]]; then
            season_number="Specials"
        else
            season_number="Season $season_number"
        fi
        url_poster=$(echo "$season" | jq -r .url_poster)
        md_link="[$season_number]($url_poster)"
        if [[ $first -eq 1 ]]; then
            output="\"$md_link\""
            first=0
        else
            output="$output,\"$md_link\""
        fi
    done < <(echo "$seasons_json" | jq -c '.[]')
    # Output as a JSON array
    echo "[$output]"
}

is_movies=false
is_shows=false
while read -r item; do
    # Process each item in the array
    title=$(echo "$item" | jq -r .label_title)
    release_year=$(echo "$item" | jq -r .release_year)
    url_poster=$(echo "$item" | jq -r .url_poster)
    txdb_id=$(echo "$item" | jq -r .txdb_id)
    genres=$(echo "$item" | jq -r '."genre.sync"')
    if echo "$item" | jq 'has("seasons")' | grep -q true; then
        # Extract the "seasons" object and convert it to an array of objects with "season_number" and its value
        seasons="$(echo "$item" | jq -c '[.seasons | to_entries[] | {season_number: .key, url_poster: .value.url_poster}]')"
        seasons_md_links="$(seasons_to_md_links "$seasons")"
        txbd_url="https://www.thetvdb.com/dereferrer/series/${txdb_id}"
        echo "| [$txdb_id]($txbd_url) | $title | $release_year | [Preview]($url_poster) | $(array_to_html_list "$genres") | $(array_to_html_list "$seasons_md_links") |" >> "$temp_show_file"
        is_shows=true
    else
        txbd_url="https://www.themoviedb.org/movie/${txdb_id}"
        echo "| [$txdb_id]($txbd_url) | $title | $release_year | [Preview]($url_poster) | $(array_to_html_list "$genres") |" >> "$temp_movie_file"
        is_movies=true
    fi
done < <(echo "$json_array" | jq -c '.[]')

if $is_movies; then
    echo "## Movies" >> "$output_md_file"
    cat "$temp_movie_file" >> "$output_md_file"
fi
if $is_movies && $is_shows; then
    echo "<br><br>" >> "$output_md_file"
fi
if $is_shows; then
    echo "## TV Shows" >> "$output_md_file"
    cat "$temp_show_file" >> "$output_md_file"
fi

rm -f "$temp_movie_file" "$temp_show_file"

