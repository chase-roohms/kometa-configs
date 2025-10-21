#!/bin/bash

# Get TVDb auth token using the API token.
# Usage: get_auth_token.sh <access_token>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <access_token>"
    exit 1
fi

access_token="$1"

payload=$(jq -n --arg apikey "$access_token" '{apikey: $apikey}')

response_file=$(mktemp)
http_code=$(curl -s -w "%{http_code}" -o "$response_file" \
    --request POST \
    --url "https://api4.thetvdb.com/v4/login" \
    --header "Content-Type: application/json" \
    --data "$payload")

if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    jq -r .data.token < "$response_file"
    rm -f "$response_file"
    exit 0
else
    jq . < "$response_file" >&2 || cat "$response_file" >&2
    echo "Error: HTTP $http_code" >&2
    rm -f "$response_file"
    exit 1
fi