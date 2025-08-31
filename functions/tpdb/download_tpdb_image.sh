#!/bin/bash

# Download an image from TPDb using either a direct API URL or TPDb asset ID.
# Usage: download_tpdb_image.sh <url|tpdb_id> <collection_id> <output_directory>
# Example: download_tpdb_image.sh 123456
#          download_tpdb_image.sh https://theposterdb.com/api/assets/123456

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <url|tpdb_id> <collection_id> <output_directory>"
    exit 1
fi

url="$1"
collection_id="$2"
output_directory="$3"

if [[ ! "$url" =~ ^https://theposterdb\.com/api/assets/ ]] && [[ ! "$url" =~ ^[0-9]+$ ]]; then
    echo "Error: URL must start with 'https://theposterdb.com/api/assets/' or be just a TPDb ID."
    exit 1
fi

# If url is just an integer, convert it to the full API URL
if [[ "$url" =~ ^[0-9]+$ ]]; then
    url="https://theposterdb.com/api/assets/$url"
fi

user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
tmp_file=$(mktemp "${collection_id}.XXXXXX.tmp")

# Download with single curl and extract content type from response headers
response=$(curl -sD - -A "$user_agent" "$url" -o "$tmp_file")
content_type=$(echo "$response" | grep -i '^Content-Type:' | awk '{print $2}' | tr -d '\r')

# Map content type to extension
case "$content_type" in
    image/jpeg) ext="jpg" ;;
    image/png) ext="png" ;;
    image/webp) ext="webp" ;;
    *) ext="img" ;;
esac

# Rename file with correct extension
cp "$tmp_file" "${output_directory}/${collection_id}.${ext}"