## Session Behavior

1. **Read AGENTS.md at session start**: Always read this file at the beginning of every session
2. **Follow all rules below** for the duration of the session

## SDD methodology (optional)

1. The Uncle Bob SDD methodology (craftsman_lead + spec_partner + gherkin_author + tdd_craftsman + judge + mutation_tester) is **OPTIONAL**.
2. **Use it only when the user explicitly asks for it** (e.g. "use SDD", "follow the methodology", "run the pipeline"). Never start spec/TDD/gate flows on your own.
3. For normal requests, work the regular way (straight to implementation) unless the user opts into SDD.


## Commits

1. **Not commit**: avoid do commits unless explicitly asked
2. **Use present tense**: Write commit messages in the present tense (e.g., "Add new agent features" instead of "Added new agent features")
3. **Branch names**: Use descriptive names following the [Conventional Branch spec](https://conventionalbranch.org/) — `<type>/<description>` with lowercase alphanumerics, hyphens, dots. Valid types: `feature`/`feat`, `bugfix`/`fix`, `hotfix`, `release`, `chore`; AI agents use `ai/` (or `claude/`, `codex/`, `copilot/`, `cursor/`). Trunk branches (`main`, `master`, `develop`) have no prefix. Examples: `feature/agent-improvements`, `bugfix/agent-error-handling`, `ai/refactor-auth-flow`
4. **Commit messages**: Clear and concise, explain the "why" not just the "what"
5. **Single-line messages**: Use only a one-line commit message with no body/description
6. **Make small commits**: Split changes into multiple small commits when possible for easier review
7. **commit by file**: If you have multiple files to change, consider committing changes file by file to keep commits focused and easier to understand
8. **Never push to remote**: Do NOT push commits to remote unless the user explicitly asks you to. Commits stay local only.
9. **Use super-commit workflow**: When committing, use the opencode-provided `super-commit` workflow when available. It is not a system shell command; never invoke `super-commit` through Bash. If the workflow is unavailable, use normal non-interactive git commands while following these commit rules.
10. **Create TODOs for commits**: If you have changes that are not ready to be committed, create TODO comments in the code to track what needs to be done before committing
11. **name of commits**: Always start the commits with name of the app or directory that is being changed (e.g., "zsh: Update agent configuration" or "agent: Fix error handling in agent manager")

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

## Project documentation split

Two distinct kinds of documentation, never mix them:

1. **Usage docs** — the repo's `README.md` documents how a *user* uses the tool.
2. **Build docs** — how the project is built and worked on, for LLMs/agents. For
   personal projects, this lives at
   `$HOME/workspace/sync/inbox/neutry/projects/<project>/wiki.md`. For work
   projects, it lives at
   `$HOME/workspace/sync/inbox/Projects/doitnow/<project>/wiki.md`, next to the
   project's `<project>.todos.json`. Call it `wiki.md`, not README, to avoid
   confusion.

## Project TODOs
Kanban-facing TODO IDs should use a concise project abbreviation and short slug, target 32 characters maximum, and never exceed 48 characters. When shortening an existing ID, update every dependency reference in the same change.
1. Each personal project keeps its own TODO file named `<project>.todos.json` at
   `$HOME/workspace/sync/inbox/neutry/projects/<project>/`. Each work project
   keeps it at `$HOME/workspace/sync/inbox/Projects/doitnow/<project>/` (for
   example, `Projects/doitnow/tekniker/TODOs.todos.json`). If it does not
   exist, create it.
2. Treat each project's `<project>.todos.json` as the machine-readable source of truth for that project's tasks. Use JSON because it is easy for LLMs and automation to process.
3. **Before editing any file**, read the project's `<project>.todos.json` and create a new TODO entry for the planned work with status `"pending"`.
4. Group related work into one TODO entry per cohesive task, not one entry per file or small change. Summarize all related changes, affected files, and verification results in that entry.
5. Use only these status names: `"pending"`, `"partial"`, `"completed"`, `"blocked"`, and `"rejected"`. Use `"partial"` for work that is started but not complete; `"in-progress"` is not a valid zennotes status.
6. Read the relevant TODO before work, verify the result after work, and immediately update its status, summary, affected files, and verification evidence.
7. When creating or updating TODOs, keep the user-facing summary brief: state what was created or changed and its current status.
8. Use Markdown files for project overview, decisions, and general documentation. Link to `<project>.todos.json` when both files are present.
9. Order TODO entries by execution dependency. Every task must include a `dependencies` array listing prerequisite task IDs; use an empty array only when the task has no project-task prerequisite.
10. Every task MUST include an `area` (category) and a `priority` (relevance), following the tekniker TODO format (see `$HOME/workspace/sync/inbox/Projects/tekniker/TODOs.todos.json`). Task schema:
     - `id` — unique, short, lowercase kebab-case task ID. New IDs use `<project>-<short-slug>` and should normally stay under 48 characters. Do not rename existing IDs without migrating every dependency.
    - `area` — category, e.g. `reliability`, `security`, `performance`, `features`, `ux`, `testing`, `documentation`, `operations`
    - `title` — short task title
    - `priority` — relevance: `high`, `medium`, or `low`
    - `status` — one of the statuses above
    - `dependencies` — prerequisite task IDs
    - `summary` — what was done / what remains
    - `affectedFiles` — files touched
     - `verification` — how the result was verified (optionally `verifiedAt`, `verificationEvidence`, `commits`)
11. **Create one TODO ticket per feature scenario.** For every scenario tagged `@sN` in a `.feature` file, create exactly one corresponding TODO task; do not group multiple scenarios into one ticket. The task title or summary MUST name `@sN`, and the task ID MUST use the short scenario form `<project>-sN-<short-slug>` (for example, `dirwalker-s28-read-errors`). Keep the scenario ticket's dependencies, affected files, status, and verification evidence current as the scenario moves through implementation and review.
12. **Keep scenario traceability one-to-one.** Before marking a scenario ticket completed, verify that its scenario is covered by a test or explicit review evidence. When adding, renaming, or removing scenarios, update the matching TODO ticket in the same change and run the project's TODO validator.
13. **Scenario tickets only.** The `<project>.todos.json` file contains ONLY one ticket per `@sN` scenario — never feature-level, process, docs, or bookkeeping tickets. Do NOT create a TODO ticket for anything other than a scenario. If you need to record additional info, update the matching scenario ticket (e.g. summary, affectedFiles, verification) instead of creating a new one.
