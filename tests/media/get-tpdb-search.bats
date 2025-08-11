#!/usr/bin/env bats

function setup() {
    function="functions/media/get-tpdb-search.sh"
}

@test "get tpdb search, no args" {
  run bash "$function"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <title> <type [movie|show]>" ]
}

@test "get tpdb search, one arg" {
  run bash "$function" "Test Movie"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <title> <type [movie|show]>" ]
}

@test "get tpdb search, too many args" {
  run bash "$function" "Test Movie" "movie" "extra"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <title> <type [movie|show]>" ]
}

@test "get tpdb search, invalid type" {
  run bash "$function" "Test Movie" "invalid"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: type must be either 'movie' or 'show'" ]
}

@test "get tpdb search, movie type, simple title" {
  run bash "$function" "Avatar" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=Avatar&section=movies" ]
}

@test "get tpdb search, show type, simple title" {
  run bash "$function" "Avatar" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=Avatar&section=shows" ]
}

@test "get tpdb search, movie type, title with spaces" {
  run bash "$function" "The Dark Knight" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=The+Dark+Knight&section=movies" ]
}

@test "get tpdb search, show type, title with spaces" {
  run bash "$function" "Breaking Bad" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=Breaking+Bad&section=shows" ]
}

@test "get tpdb search, movie type, title with ampersand" {
  run bash "$function" "Fast & Furious" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=Fast+%26+Furious&section=movies" ]
}

@test "get tpdb search, show type, title with ampersand" {
  run bash "$function" "Law & Order" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=Law+%26+Order&section=shows" ]
}

@test "get tpdb search, movie type, title with spaces and ampersand" {
  run bash "$function" "Ice Age: Dawn of the Dinosaurs & More" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=Ice+Age:+Dawn+of+the+Dinosaurs+%26+More&section=movies" ]
}

@test "get tpdb search, movie type, empty title" {
  run bash "$function" "" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=&section=movies" ]
}

@test "get tpdb search, show type, empty title" {
  run bash "$function" "" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=&section=shows" ]
}

@test "get tpdb search, movie type, title with special characters" {
  run bash "$function" "Spider-Man: Into the Spider-Verse" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=Spider-Man:+Into+the+Spider-Verse&section=movies" ]
}

@test "get tpdb search, show type, title with numbers" {
  run bash "$function" "24" "show"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=24&section=shows" ]
}

@test "get tpdb search, movie type, title with parentheses" {
  run bash "$function" "The Lord of the Rings (2001)" "movie"
  [ "$status" -eq 0 ]
  [ "$output" = "https://theposterdb.com/search?term=The+Lord+of+the+Rings+(2001)&section=movies" ]
}
