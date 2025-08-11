#!/usr/bin/env bats

function setup() {
    function="functions/git/set-git-config.sh"
    # Store original git config values to restore after tests
    original_email=$(git config --global user.email 2>/dev/null || echo "")
    original_name=$(git config --global user.name 2>/dev/null || echo "")
}

function teardown() {
    # Restore original git config values
    if [ -n "$original_email" ]; then
        git config --global user.email "$original_email"
    else
        git config --global --unset user.email 2>/dev/null || true
    fi
    
    if [ -n "$original_name" ]; then
        git config --global user.name "$original_name"
    else
        git config --global --unset user.name 2>/dev/null || true
    fi
}

@test "set git config, script runs successfully" {
    run bash "$function"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "set git config, sets correct email" {
    bash "$function"
    run git config --global user.email
    [ "$status" -eq 0 ]
    [ "$output" = "41898282+github-actions[bot]@users.noreply.github.com" ]
}

@test "set git config, sets correct name" {
    bash "$function"
    run git config --global user.name
    [ "$status" -eq 0 ]
    [ "$output" = "github-actions[bot]" ]
}

@test "set git config, accepts extra arguments without error" {
    run bash "$function" "extra" "args"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "set git config, overwrites existing email" {
    # Set a different email first
    git config --global user.email "test@example.com"
    
    # Run the script
    bash "$function"
    
    # Verify it was overwritten
    run git config --global user.email
    [ "$status" -eq 0 ]
    [ "$output" = "41898282+github-actions[bot]@users.noreply.github.com" ]
}

@test "set git config, overwrites existing name" {
    # Set a different name first
    git config --global user.name "Test User"
    
    # Run the script
    bash "$function"
    
    # Verify it was overwritten
    run git config --global user.name
    [ "$status" -eq 0 ]
    [ "$output" = "github-actions[bot]" ]
}

@test "set git config, both values set when starting from clean state" {
    # Clear any existing git config
    git config --global --unset user.email 2>/dev/null || true
    git config --global --unset user.name 2>/dev/null || true
    
    # Run the script
    bash "$function"
    
    # Verify both values are set correctly
    email=$(git config --global user.email)
    name=$(git config --global user.name)
    
    [ "$email" = "41898282+github-actions[bot]@users.noreply.github.com" ]
    [ "$name" = "github-actions[bot]" ]
}
