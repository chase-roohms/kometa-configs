#!/usr/bin/env bats

function setup() {
    function="functions/media/get-google-search.sh"
}

@test "get google search, no args" {
  run bash "$function"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <title> <release_year> <type [movie|show]>" ]
}

@test "get google search, one arg" {
  run bash "$function" "Test Movie"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <title> <release_year> <type [movie|show]>" ]
}

@test "get google search, two args" {
  run bash "$function" "Test Movie" "2023"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <title> <release_year> <type [movie|show]>" ]
}

@test "get google search, too many args" {
  run bash "$function" "Test Movie" "2023" "movie" "extra"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <title> <release_year> <type [movie|show]>" ]
}

@test "get google search, invalid type" {
  run bash "$function" "Test Movie" "2023" "invalid"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: type must be either 'movie' or 'show'" ]
}

@test "get google search, invalid year - not 4 digits" {
  run bash "$function" "Test Movie" "23" "movie"
  [ "$status" -eq 3 ]
  [ "$output" = "Error: release_year must be a 4-digit number" ]
}

@test "get google search, invalid year - not a number" {
  run bash "$function" "Test Movie" "abcd" "movie"
  [ "$status" -eq 3 ]
  [ "$output" = "Error: release_year must be a 4-digit number" ]
}

@test "get google search, invalid year - too many digits" {
  run bash "$function" "Test Movie" "20231" "movie"
  [ "$status" -eq 3 ]
  [ "$output" = "Error: release_year must be a 4-digit number" ]
}

@test "get google search, movie type, simple title" {
  run bash "$function" "Avatar" "2009" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=Avatar+2009+movie" ]
}

@test "get google search, show type, simple title" {
  run bash "$function" "Avatar" "2005" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=Avatar+2005+show" ]
}

@test "get google search, movie type, title with spaces" {
  run bash "$function" "The Dark Knight" "2008" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=The+Dark+Knight+2008+movie" ]
}

@test "get google search, show type, title with spaces" {
  run bash "$function" "Breaking Bad" "2008" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=Breaking+Bad+2008+show" ]
}

@test "get google search, movie type, title with ampersand" {
  run bash "$function" "Fast & Furious" "2009" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=Fast+%26+Furious+2009+movie" ]
}

@test "get google search, show type, title with ampersand" {
  run bash "$function" "Law & Order" "1990" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=Law+%26+Order+1990+show" ]
}

@test "get google search, movie type, title with spaces and ampersand" {
  run bash "$function" "Ice Age: Dawn of the Dinosaurs & More" "2009" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=Ice+Age:+Dawn+of+the+Dinosaurs+%26+More+2009+movie" ]
}

@test "get google search, movie type, empty title" {
  run bash "$function" "" "2023" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=+2023+movie" ]
}

@test "get google search, show type, empty title" {
  run bash "$function" "" "2023" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=+2023+show" ]
}

@test "get google search, movie type, title with special characters" {
  run bash "$function" "Spider-Man: Into the Spider-Verse" "2018" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=Spider-Man:+Into+the+Spider-Verse+2018+movie" ]
}

@test "get google search, show type, title with numbers" {
  run bash "$function" "24" "2001" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=24+2001+show" ]
}

@test "get google search, movie type, title with parentheses" {
  run bash "$function" "The Lord of the Rings (Fellowship)" "2001" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=The+Lord+of+the+Rings+(Fellowship)+2001+movie" ]
}

@test "get google search, movie type, edge case year 1000" {
  run bash "$function" "Ancient Movie" "1000" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=Ancient+Movie+1000+movie" ]
}

@test "get google search, movie type, edge case year 9999" {
  run bash "$function" "Future Movie" "9999" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.google.com/search?q=Future+Movie+9999+movie" ]
}
