#!/usr/bin/env bats

function setup() {
    function="functions/media/get-tmdb-link.sh"
}

@test "get tmdb link, no args" {
  run bash "$function"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <tmdb_id>" ]
}

@test "get tmdb link, too many args" {
  run bash "$function" "12345" "extra"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <tmdb_id>" ]
}

@test "get tmdb link, invalid id - not a number" {
  run bash "$function" "abc"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tmdb_id must be a number" ]
}

@test "get tmdb link, invalid id - contains letters" {
  run bash "$function" "123abc"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tmdb_id must be a number" ]
}

@test "get tmdb link, invalid id - negative number" {
  run bash "$function" "-123"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tmdb_id must be a number" ]
}

@test "get tmdb link, invalid id - decimal number" {
  run bash "$function" "123.45"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tmdb_id must be a number" ]
}

@test "get tmdb link, invalid id - empty string" {
  run bash "$function" ""
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tmdb_id must be a number" ]
}

@test "get tmdb link, invalid id - special characters" {
  run bash "$function" "123@456"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tmdb_id must be a number" ]
}

@test "get tmdb link, valid id - single digit" {
  run bash "$function" "1"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.themoviedb.org/movie/1" ]
}

@test "get tmdb link, valid id - multiple digits" {
  run bash "$function" "12345"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.themoviedb.org/movie/12345" ]
}

@test "get tmdb link, valid id - zero" {
  run bash "$function" "0"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.themoviedb.org/movie/0" ]
}

@test "get tmdb link, valid id - large number" {
  run bash "$function" "999999999"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.themoviedb.org/movie/999999999" ]
}

@test "get tmdb link, valid id - common movie ids" {
  run bash "$function" "550"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.themoviedb.org/movie/550" ]
}

@test "get tmdb link, valid id - avatar movie id" {
  run bash "$function" "19995"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.themoviedb.org/movie/19995" ]
}

@test "get tmdb link, valid id - dark knight movie id" {
  run bash "$function" "155"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.themoviedb.org/movie/155" ]
}

@test "get tmdb link, valid id - leading zeros stripped" {
  run bash "$function" "00123"
  [ "$status" -eq 0 ]
  [ "$output" = "https://www.themoviedb.org/movie/00123" ]
}
