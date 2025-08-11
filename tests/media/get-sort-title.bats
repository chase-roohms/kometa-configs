#!/usr/bin/env bats

function setup() {
    function="functions/media/get-sort-title.sh"
    emoji="🦊"
    number="³"
    number_translated="^3"
    letter="ó"
    letter_translated="'o"
}

@test "get sort title, missing args" {
  run bash "$function" 
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <title>" ]
}

@test "get sort title, extra args" {
  run bash "$function" "QUICK BROWN FOX" "Extra Arg"
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: $function <title>" ]
}

@test "get sort title, uppercase, no articles" {
  run bash "$function" "QUICK BROWN FOX"
  [ "$status" -eq 0 ]
  [ "$output" = "QUICK BROWN FOX" ]
}

@test "get sort title, lowercase, no articles" {
  run bash "$function" "quick brown fox"
  [ "$status" -eq 0 ]
  [ "$output" = "quick brown fox" ]
}

@test "get sort title, mixed case, no articles" {
  run bash "$function" "QuIcK bRoWn FoX"
  [ "$status" -eq 0 ]
  [ "$output" = "QuIcK bRoWn FoX" ]
}

@test "get sort title, emoji, no articles" {
  run bash "$function" "Quick Brown Fox $emoji"
  [ "$status" -eq 0 ]
  [ "$output" = "Quick Brown Fox" ]
}

@test "get sort title, special letter, no articles" {
  run bash "$function" "Quick Br${letter}wn F${letter}x"
  [ "$status" -eq 0 ]
  [ "$output" = "Quick Br${letter_translated}wn F${letter_translated}x" ]
}

@test "get sort title, special number, no articles" {
  run bash "$function" "Quick Brown Fox${number}"
  [ "$status" -eq 0 ]
  [ "$output" = "Quick Brown Fox${number_translated}" ]
}

@test "get sort title, uppercase, article" {
  run bash "$function" "THE QUICK BROWN FOX"
  [ "$status" -eq 0 ]
  [ "$output" = "QUICK BROWN FOX" ]
}

@test "get sort title, lowercase, article" {
  run bash "$function" "the quick brown fox"
  [ "$status" -eq 0 ]
  [ "$output" = "quick brown fox" ]
}

@test "get sort title, mixed case, article" {
  run bash "$function" "ThE QuIcK bRoWn FoX"
  [ "$status" -eq 0 ]
  [ "$output" = "QuIcK bRoWn FoX" ]
}

@test "get sort title, emoji, article" {
  run bash "$function" "The Quick Brown Fox $emoji"
  [ "$status" -eq 0 ]
  [ "$output" = "Quick Brown Fox" ]
}

@test "get sort title, special letter, article" {
  run bash "$function" "The Quick Br${letter}wn F${letter}x"
  [ "$status" -eq 0 ]
  [ "$output" = "Quick Br${letter_translated}wn F${letter_translated}x" ]
}

@test "get sort title, special number, article" {
  run bash "$function" "The Quick Brown Fox${number}"
  [ "$status" -eq 0 ]
  [ "$output" = "Quick Brown Fox${number_translated}" ]
}

@test "get sort title, multiple articles" {
  run bash "$function" "The Quick Brown Fox Jumped Over The Lazy Dog"
  [ "$status" -eq 0 ]
  [ "$output" = "Quick Brown Fox Jumped Over The Lazy Dog" ]
}

@test "get sort title, all numbers" {
  run bash "$function" "1234567890"
  [ "$status" -eq 0 ]
  [ "$output" = "1234567890" ]
}

@test "get sort title, empty string" {
  run bash "$function" ""
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}