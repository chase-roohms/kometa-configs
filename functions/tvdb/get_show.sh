#!/bin/bash

# Get show details from TVDb using the show ID and an access token.
# Usage: get_show.sh <show_id> <access_token>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <show_id> <access_token>"
    exit 1
fi

tvdb_id="$1"
access_token="$2"

response_file=$(mktemp)
http_code=$(curl -s -w "%{http_code}" -o "$response_file" --request GET \
     --url "https://api4.thetvdb.com/v4/series/$tvdb_id/episodes/default" \
     --header "Authorization: Bearer $access_token")

if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    jq . < "$response_file"
    rm -f "$response_file"
    exit 0
else
    jq . < "$response_file" >&2 || cat "$response_file" >&2
    echo "Error: HTTP $http_code" >&2
    rm -f "$response_file"
    exit 1
fi