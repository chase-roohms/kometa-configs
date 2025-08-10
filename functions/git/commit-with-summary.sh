#!/bin/bash

if [ $# -lt 3 ]; then
  echo "Usage: $0 <commit_message> <update_summary_file> <file1> [file2 ...]" >&2
  exit 1
fi

commit_message="$1"
update_summary_file="$2"
shift 2
files=("$@")

# Check that all files exist
for file in "${files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Error: File '$file' does not exist." >&2
    exit 1
  fi
done

old_sha=$(git rev-parse HEAD)
git add "${files[@]}"
if ! git diff-index --quiet main; then
  git commit -m "$commit_message" >> "$update_summary_file"
  git push >> "$update_summary_file"
  new_sha=$(git rev-parse HEAD)
  git diff --unified=0 --no-color "$old_sha" "$new_sha" >> "$update_summary_file"
  sha=$new_sha
else
  echo "No changes to commit." >> "$update_summary_file"
  sha=$old_sha
fi

echo "$sha"
