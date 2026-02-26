---
name: test-gen
description: Generate tests for functions and modules
license: MIT
user-invocable: true
allowed-tools:
  - read_file
  - grep
  - write_file
---

Generate comprehensive tests for the specified function/module.

## Steps
1. Read the target code in full
2. Identify: inputs, outputs, edge cases, error conditions
3. Write tests covering: happy path, edge cases, error cases
4. Follow existing test patterns in the codebase
5. Report test coverage achieved
