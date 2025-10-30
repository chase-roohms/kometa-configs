#!/bin/bash

# Get English show title from TVDb using the series ID and an auth token.
# Automatically removes trailing year in parentheses (e.g., "Archer (2009)" -> "Archer")
# Usage: get_english_show_title.sh <series_id> <auth_token>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <series_id> <auth_token>"
    exit 1
fi

tvdb_id="$1"
auth_token="$2"

response_file=$(mktemp)
http_code=$(curl -s -w "%{http_code}" -o "$response_file" --request GET \
     --url "https://api4.thetvdb.com/v4/series/$tvdb_id/translations/eng" \
     --header "Authorization: Bearer $auth_token")

if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    # Extract English title and remove trailing year in parentheses
    jq -r '.data.name' < "$response_file" | sed 's/ ([0-9]\{4\})$//'
    rm -f "$response_file"
    exit 0
else
    jq . < "$response_file" >&2 || cat "$response_file" >&2
    echo "Error: HTTP $http_code" >&2
    rm -f "$response_file"
    exit 1
fi
