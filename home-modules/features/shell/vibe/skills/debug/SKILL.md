---
name: debug
description: Systematic debugging workflow for errors and unexpected behavior
license: MIT
user-invocable: true
allowed-tools:
  - read_file
  - grep
  - bash
---

Debug the reported issue systematically.

## Steps
1. Reproduce the error (run the failing command/test)
2. Read the full error output carefully
3. Trace the error to its root cause in the source
4. Do NOT make random changes — understand before fixing
5. Apply the minimal fix
6. Verify the fix resolves the issue
7. Check for regressions
