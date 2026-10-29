## Session Behavior

1. **Read AGENTS.md at session start**: Always read this file at the beginning of every session
2. **Follow all rules below** for the duration of the session


## Commits

1. **Not commit**: avoid do commits unless explicitly asked
2. **Use present tense**: Write commit messages in the present tense (e.g., "Add new agent features" instead of "Added new agent features")
3. **Branch names**: Use descriptive names following the [Conventional Branch spec](https://conventionalbranch.org/) — `<type>/<description>` with lowercase alphanumerics, hyphens, dots. Valid types: `feature`/`feat`, `bugfix`/`fix`, `hotfix`, `release`, `chore`; Trunk branches (`main`, `master`, `develop`) have no prefix. Examples: `feature/agent-improvements`, `bugfix/agent-error-handling`, `ai/refactor-auth-flow`, for release branches use `release/<version>` (e.g., `release/1.2.3`).
4. **Commit messages**: Use the repository's Conventional Commits style: `<type>(<scope>): <description>` (for example, `feat(prometheus-bridge): add polling adapter`, `fix(deploy): correct runner configuration`, or `ci: route validation jobs`). Keep messages clear, concise, and in present tense.
5. **Single-line messages**: Use only a one-line commit message with no body/description
6. **Make small commits**: Split changes into multiple small commits when possible for easier review
7. **commit by file**: If you have multiple files to change, consider committing changes file by file to keep commits focused and easier to understand
8. **Never push to remote**: Do NOT push commits to remote unless the user explicitly asks you to. Commits stay local only.
9. **Use super-commit workflow**: When committing, use the opencode-provided `super-commit` workflow when available. It is not a system shell command; never invoke `super-commit` through Bash. If the workflow is unavailable, use normal non-interactive git commands while following these commit rules.
10. **Create TODOs for commits**: If you have changes that are not ready to be committed, create TODO comments in the code to track what needs to be done before committing
11. **Scopes**: Use an optional Conventional Commit scope when it identifies the affected component or directory. Do not require an application or directory prefix outside the Conventional Commit format.

## Cluster Changes

1. **GitOps only**: Never apply configuration directly to the Kubernetes cluster. Change the repository manifests and let the configured GitOps workflow synchronize them.

## README.md Updates

For agent documentation, follow these rules:
1. Do NOT add project structure unless explicitly asked
2. Do NOT add examples unless explicitly aske


## Manual Changes Detection

When files have been manually deleted or modified by the user after the model made changes:
1. Check for missing files or unexpected changes before making new edits
2. If files are missing that the model previously created, ask the user:
   - "Do you want to add this info back?"
   - "Do you want to update over your manual changes?"
3. Never automatically restore or recreate files without explicit permission

## Memory
1. Always use engram to get context of project

## Test Location

**MANDATORY: ALWAYS create tests inside the project's `testing/` directory.**
Never place `_test.go` or other test files beside production source under
`internal/`, `cmd/`, or any other source directory. Use an external test
package when necessary and export only the production symbols the tests need.

