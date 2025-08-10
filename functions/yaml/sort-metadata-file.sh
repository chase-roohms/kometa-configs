#!/bin/bash

# Check if a file path is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <file-path>"
  exit 1
fi

METADATA_FILE="$1"

# Check if the file exists
if [ ! -f "$METADATA_FILE" ]; then
  echo "File not found: $METADATA_FILE"
  exit 1
fi

# Sort entries by "sort_title"
yq -i '
  .metadata |= (
    to_entries
      | map(
        .value.temp_sort = (
          (.value.sort_title | downcase)
          | sub("\\b([0-9])\\b"; "00000${1}")
          | sub("\\b([0-9]{2})\\b"; "0000${1}")
          | sub("\\b([0-9]{3})\\b"; "000${1}")
          | sub("\\b([0-9]{4})\\b"; "00${1}")
          | sub("\\b([0-9]{5})\\b"; "0${1}")
        )
      )
    | sort_by(.value.temp_sort)
    | map(.value |= del(.temp_sort))
    | from_entries
  )
' "$METADATA_FILE"

# Sort metadata entries
yq -i '
  .metadata |= with_entries(
    .value |= (
      {
        "label_title": .label_title,
        "sort_title": .sort_title,
        "release_year": .release_year,
        "url_poster": .url_poster,
        "tpdb_search": .tpdb_search,
        "audio_language": .audio_language,
        "studio": .studio,
        "episode_ordering": .episode_ordering,
        "genre.sync": ."genre.sync",
        "seasons": .seasons
      }
    )
  )
' "$METADATA_FILE"

# Sort seasons by keys numerically if present
yq -i '
  (.metadata[] | select(.seasons) | .seasons) |= (to_entries | sort_by(.key | tonumber) | from_entries)
' "$METADATA_FILE"

yq -i '.metadata[] |= (.["genre.sync"] = (.["genre.sync"] // [] ) | .["genre.sync"] |= sort)' "$METADATA_FILE"

# Remove non-required fields if they are null
non_required_fields=("studio" "audio_language" "episode_ordering" "seasons")
for field in "${non_required_fields[@]}"; do
  yq -i "
    .metadata |= with_entries(
      .value |= del(.$field | select(. == null))
    )
  " "$METADATA_FILE"
done
