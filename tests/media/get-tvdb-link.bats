#!/usr/bin/env bats

function setup() {
    function="functions/media/get-tvdb-link.sh"
}

@test "get tvdb link, no args" {
  run bash "$function"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <tvdb_id>" ]
}

@test "get tvdb link, too many args" {
  run bash "$function" "12345" "extra"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <tvdb_id>" ]
}

@test "get tvdb link, invalid id - not a number" {
  run bash "$function" "abc"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tvdb_id must be a number" ]
}

@test "get tvdb link, invalid id - contains letters" {
  run bash "$function" "123abc"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tvdb_id must be a number" ]
}

@test "get tvdb link, invalid id - negative number" {
  run bash "$function" "-123"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tvdb_id must be a number" ]
}

@test "get tvdb link, invalid id - decimal number" {
  run bash "$function" "123.45"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tvdb_id must be a number" ]
}

@test "get tvdb link, invalid id - empty string" {
  run bash "$function" ""
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tvdb_id must be a number" ]
}

@test "get tvdb link, invalid id - special characters" {
  run bash "$function" "123@456"
  [ "$status" -eq 2 ]
  [ "$output" = "Error: tvdb_id must be a number" ]
}

@test "get tvdb link, valid id - single digit" {
  run bash "$function" "1"
  [ "$status" -eq 0 ]
  [ "$output" = "https://thetvdb.com/dereferrer/series/1" ]
}

@test "get tvdb link, valid id - multiple digits" {
  run bash "$function" "12345"
  [ "$status" -eq 0 ]
  [ "$output" = "https://thetvdb.com/dereferrer/series/12345" ]
}

@test "get tvdb link, valid id - zero" {
  run bash "$function" "0"
  [ "$status" -eq 0 ]
  [ "$output" = "https://thetvdb.com/dereferrer/series/0" ]
}

@test "get tvdb link, valid id - large number" {
  run bash "$function" "999999999"
  [ "$status" -eq 0 ]
  [ "$output" = "https://thetvdb.com/dereferrer/series/999999999" ]
}

@test "get tvdb link, valid id - common show ids" {
  run bash "$function" "73739"
  [ "$status" -eq 0 ]
  [ "$output" = "https://thetvdb.com/dereferrer/series/73739" ]
}

@test "get tvdb link, valid id - breaking bad show id" {
  run bash "$function" "81189"
  [ "$status" -eq 0 ]
  [ "$output" = "https://thetvdb.com/dereferrer/series/81189" ]
}

@test "get tvdb link, valid id - game of thrones show id" {
  run bash "$function" "121361"
  [ "$status" -eq 0 ]
  [ "$output" = "https://thetvdb.com/dereferrer/series/121361" ]
}

@test "get tvdb link, valid id - leading zeros stripped" {
  run bash "$function" "00123"
  [ "$status" -eq 0 ]
  [ "$output" = "https://thetvdb.com/dereferrer/series/00123" ]
}
