# Tests

This directory contains the test suite for the kometa-configs utility functions, written using the [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core) testing framework.

## Overview

The test suite ensures the reliability and correctness of the shell scripts in the `functions/` directory. Tests are organized by category to match the function structure:

```
tests/
├── git/           # Tests for git-related functions
├── media/         # Tests for media processing functions
├── strings/       # Tests for string manipulation functions
└── yaml/          # Tests for YAML processing functions
```

## Test Structure

Each test file follows the naming convention `<function-name>.bats` and mirrors the structure of the corresponding function in the `functions/` directory.

### Current Test Coverage

#### Git Functions (`tests/git/`)
- **`set-git-config.bats`** - Tests for `functions/git/set-git-config.sh`
  - ✅ Script execution validation
  - ✅ Git configuration setting verification
  - ✅ Overwrite behavior testing
  - ✅ Configuration cleanup and restoration

#### Media Functions (`tests/media/`)
- **`get-sort-title.bats`** - Tests for `functions/media/get-sort-title.sh`
  - ✅ Article removal functionality
  - ✅ Special character handling
  - ✅ Case preservation
  - ✅ Emoji and unicode processing
  - ✅ Argument validation

- **`get-tpdb-search.bats`** - Tests for `functions/media/get-tpdb-search.sh`
  - ✅ Argument validation (count and type)
  - ✅ URL encoding (spaces, ampersands, special characters)
  - ✅ Movie vs. show section handling
  - ✅ Edge cases (empty titles, complex strings)

#### String Functions (`tests/strings/`)
- **Pending**: Tests for `functions/strings/pretty-print-json-metadata.sh`

#### YAML Functions (`tests/yaml/`)
- **Pending**: Tests for the following functions:
  - `functions/yaml/find-field.sh`
  - `functions/yaml/format-metadata-file.sh`
  - `functions/yaml/insert-media-item.sh`
  - `functions/yaml/sort-metadata-file.sh`

## Running Tests

### Prerequisites

Install Bats testing framework:

```bash
# macOS (using Homebrew)
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# Or install from source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Running Individual Test Files

```bash
# Run tests for a specific function
bats tests/media/get-sort-title.bats

# Run with verbose output
bats tests/media/get-sort-title.bats --verbose-run

# Run with timing information
bats tests/media/get-sort-title.bats --timing
```

### Running All Tests

```bash
# Run all tests in a category
bats tests/media/

# Run all tests
bats tests/ -r
```

## Test Patterns and Conventions

### File Structure
Each test file follows this pattern:

```bash
#!/usr/bin/env bats

function setup() {
    function="functions/category/script-name.sh"
    # Additional setup variables
}

function teardown() {
    # Cleanup operations (if needed)
}

@test "descriptive test name" {
    run bash "$function" [arguments]
    [ "$status" -eq expected_exit_code ]
    [ "$output" = "expected_output" ]
}
```

### Test Categories

1. **Argument Validation Tests**
   - Missing arguments
   - Extra arguments  
   - Invalid argument types

2. **Functionality Tests**
   - Core behavior validation
   - Edge cases
   - Special character handling
   - Empty input handling

3. **Output Validation Tests**
   - Exact output matching
   - Exit code verification
   - Error message validation

4. **Safety Tests**
   - Configuration restoration
   - Side effect cleanup
   - State isolation

### Best Practices

- **Descriptive Names**: Test names should clearly describe what is being tested
- **Isolation**: Each test should be independent and not rely on other tests
- **Cleanup**: Use setup/teardown functions for configuration management
- **Edge Cases**: Include tests for boundary conditions and error scenarios
- **Exit Codes**: Always verify both output content and exit status

## Adding New Tests

When adding tests for new functions:

1. Create a new `.bats` file in the appropriate category directory
2. Follow the established naming convention: `<function-name>.bats`
3. Include comprehensive test coverage:
   - Argument validation
   - Core functionality
   - Edge cases
   - Error conditions
4. Add appropriate setup/teardown if the function has side effects

## Contributing

When contributing new tests:

1. Ensure tests follow the established patterns
2. Include both positive and negative test cases
3. Test edge cases and error conditions
4. Verify tests pass before submitting
5. Update documentation as needed

## Troubleshooting

### Common Issues

- **Path Issues**: Use absolute paths when referencing functions
- **Environment**: Tests may behave differently in different shell environments

### Debug Mode

Run tests with debug output:

```bash
bats --verbose-run --show-output-of-passing-tests tests/media/get-sort-title.bats
```
