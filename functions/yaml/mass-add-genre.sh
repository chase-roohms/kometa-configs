#!/bin/bash

set -o pipefail

usage() {
    cat <<'EOF'
Usage: mass-add-war-genre.sh --genre NAME [--type movie|show|all] [--env-file PATH] [--max-items N] [--dry-run]

Reads TMDB_READ_TOKEN and TVDB_TOKEN from .env, checks the existing metadata files,
and adds the requested genre to genre.sync for any movie or show whose remote genres include it.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

genre=""
type="all"
env_file="$repo_root/.env"
movie_metadata_file="$repo_root/movie-metadata.yml"
show_metadata_file="$repo_root/show-metadata.yml"
dry_run=false
max_items=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --genre)
            genre="$2"
            shift 2
            ;;
        --type)
            type="$2"
            shift 2
            ;;
        --env-file)
            env_file="$2"
            shift 2
            ;;
        --max-items)
            max_items="$2"
            shift 2
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$genre" ]]; then
    echo "Error: --genre is required" >&2
    usage >&2
    exit 1
fi

genre="$(echo "$genre" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

if [[ -z "$genre" ]]; then
    echo "Error: --genre cannot be empty" >&2
    exit 1
fi

genre_lookup="$(echo "$genre" | tr '[:upper:]' '[:lower:]')"

if [[ "$type" != "movie" && "$type" != "show" && "$type" != "all" ]]; then
    echo "Error: --type must be movie, show, or all" >&2
    exit 1
fi

if ! [[ "$max_items" =~ ^[0-9]+$ ]]; then
    echo "Error: --max-items must be a non-negative integer" >&2
    exit 1
fi

if [[ ! -f "$env_file" ]]; then
    echo "Error: env file not found at '$env_file'" >&2
    exit 1
fi

if [[ ! -f "$movie_metadata_file" ]]; then
    echo "Error: movie metadata file not found at '$movie_metadata_file'" >&2
    exit 1
fi

if [[ ! -f "$show_metadata_file" ]]; then
    echo "Error: show metadata file not found at '$show_metadata_file'" >&2
    exit 1
fi

set -a
source "$env_file"
set +a

tmdb_token="${TMDB_READ_TOKEN:-}"
tvdb_api_key="${TVDB_TOKEN:-}"

if [[ -z "$tmdb_token" ]]; then
    echo "Error: TMDB_READ_TOKEN is not set in '$env_file'" >&2
    exit 1
fi

if [[ -z "$tvdb_api_key" ]]; then
    echo "Error: TVDB_TOKEN is not set in '$env_file'" >&2
    exit 1
fi

tmdb_get_movie_script="$script_dir/../tmdb/get_movie.sh"
tvdb_get_auth_token_script="$script_dir/../tvdb/get_auth_token.sh"
sort_metadata_script="$script_dir/sort-metadata-file.sh"
format_metadata_script="$script_dir/format-metadata-file.sh"

for required_script in "$tmdb_get_movie_script" "$tvdb_get_auth_token_script" "$sort_metadata_script" "$format_metadata_script"; do
    if [[ ! -f "$required_script" ]]; then
        echo "Error: required script not found at '$required_script'" >&2
        exit 1
    fi
done

echo "Getting TVDb auth token..."
tvdb_auth_token="$(bash "$tvdb_get_auth_token_script" "$tvdb_api_key" 2>/dev/null)"

if [[ $? -ne 0 || -z "$tvdb_auth_token" ]]; then
    echo "Error: failed to retrieve TVDb auth token" >&2
    exit 1
fi

fetch_tvdb_series() {
    local tvdb_id="$1"
    local response_file
    local http_code

    response_file="$(mktemp)"
    http_code=$(curl -s -w "%{http_code}" -o "$response_file" --request GET \
        --url "https://api4.thetvdb.com/v4/series/${tvdb_id}/extended?short=true" \
        --header "Authorization: Bearer ${tvdb_auth_token}")

    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        cat "$response_file"
        rm -f "$response_file"
        return 0
    fi

    jq . < "$response_file" >&2 2>/dev/null || cat "$response_file" >&2
    echo "Error: HTTP $http_code" >&2
    rm -f "$response_file"
    return 1
}

update_genre_sync() {
    local metadata_file="$1"
    local media_id="$2"
    local label="$3"

    if [[ "$dry_run" == true ]]; then
        echo "  Would add ${genre} to genre.sync for ${label} (${media_id})"
        return 0
    fi

    yq eval -i ".metadata.${media_id}.\"genre.sync\" = ((.metadata.${media_id}.\"genre.sync\" // []) + [\"${genre}\"] | unique | sort)" "$metadata_file"
}

has_genre_locally() {
    local metadata_file="$1"
    local media_id="$2"

    yq eval -e ".metadata.${media_id}.\"genre.sync\" // [] | any((. | downcase) == \"${genre_lookup}\")" "$metadata_file" >/dev/null 2>&1
}

process_items() {
    local media_type="$1"
    local metadata_file="$2"
    local ids
    local total_items=0
    local processed=0
    local updated=0
    local skipped=0
    local errors=0

    ids="$(yq eval '.metadata | keys | .[]' "$metadata_file")"

    if [[ -z "$ids" ]]; then
        echo "No ${media_type} IDs found in $metadata_file"
        return 0
    fi

    total_items=$(echo "$ids" | wc -l | tr -d ' ')
    echo "Checking ${total_items} ${media_type} entries in $(basename "$metadata_file")"

    while IFS= read -r media_id; do
        local payload
        local label_title
        local has_remote_genre=false

        if [[ -z "$media_id" ]]; then
            continue
        fi

        if [[ "$max_items" -gt 0 && "$processed" -ge "$max_items" ]]; then
            break
        fi

        processed=$((processed + 1))
        label_title="$(yq eval ".metadata.${media_id}.label_title" "$metadata_file")"
        echo "[${processed}] ${media_type} ${media_id}: ${label_title}"

        if has_genre_locally "$metadata_file" "$media_id"; then
            echo "  ${genre} already present"
            skipped=$((skipped + 1))
            continue
        fi

        if [[ "$media_type" == "movie" ]]; then
            payload="$(bash "$tmdb_get_movie_script" "$media_id" "$tmdb_token" 2>/dev/null)"
        else
            payload="$(fetch_tvdb_series "$media_id" 2>/dev/null)"
        fi

        if [[ $? -ne 0 || -z "$payload" ]]; then
            echo "  Error: failed to fetch remote details"
            errors=$((errors + 1))
            continue
        fi

        if echo "$payload" | jq -e --arg genre "$genre_lookup" '(.genres // []) | any((.name // "") | ascii_downcase == $genre)' >/dev/null 2>&1; then
            has_remote_genre=true
        fi

        if [[ "$has_remote_genre" == true ]]; then
            update_genre_sync "$metadata_file" "$media_id" "$label_title"
            updated=$((updated + 1))
        else
            echo "  Remote genres do not include ${genre}"
            skipped=$((skipped + 1))
        fi

        if [[ "$media_type" == "movie" ]]; then
            sleep 0.25
        else
            sleep 0.5
        fi
    done <<< "$ids"

    echo "Summary for ${media_type}s: processed=${processed}, updated=${updated}, skipped=${skipped}, errors=${errors}"

    if [[ "$errors" -gt 0 ]]; then
        return 1
    fi

    return 0
}

status=0

if [[ "$type" == "movie" || "$type" == "all" ]]; then
    process_items "movie" "$movie_metadata_file" || status=1
fi

if [[ "$type" == "show" || "$type" == "all" ]]; then
    process_items "show" "$show_metadata_file" || status=1
fi

if [[ "$dry_run" == false ]]; then
    if [[ "$type" == "movie" || "$type" == "all" ]]; then
        bash "$sort_metadata_script" "$movie_metadata_file"
        bash "$format_metadata_script" "$movie_metadata_file"
    fi

    if [[ "$type" == "show" || "$type" == "all" ]]; then
        bash "$sort_metadata_script" "$show_metadata_file"
        bash "$format_metadata_script" "$show_metadata_file"
    fi
fi

exit "$status"