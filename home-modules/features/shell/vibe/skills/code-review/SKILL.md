---
name: code-review
description: Systematic code review with quality scoring
license: MIT
user-invocable: true
allowed-tools:
  - read_file
  - grep
---

Perform a structured code review of the target files or diff.

## Steps
1. Read all changed files in full
2. Check for logic errors, security issues, performance problems
3. Verify style consistency with the rest of the codebase
4. Report findings as: [CRITICAL/MAJOR/MINOR] file:line — description
5. Give an overall score /10
