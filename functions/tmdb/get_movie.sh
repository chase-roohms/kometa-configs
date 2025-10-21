#!/bin/bash

# Get movie details from TMDb using the movie ID and an access token.
# Usage: get_movie.sh <movie_id> <access_token>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <movie_id> <access_token>"
    exit 1
fi

tmdb_id="$1"
access_token="$2"

response_file=$(mktemp)
http_code=$(curl -s -w "%{http_code}" -o "$response_file" --request GET \
     --url "https://api.themoviedb.org/3/movie/$tmdb_id" \
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