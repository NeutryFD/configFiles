## Session Behavior

1. **Read AGENTS.md at session start**: Always read this file at the beginning of every session
2. **Follow all rules below** for the duration of the session


## Commits

1. **Not commit**: avoid do commits unless explicitly asked
2. **Use present tense**: Write commit messages in the present tense (e.g., "Add new agent features" instead of "Added new agent features")
3. **Branch names**: Use descriptive names (e.g., `feature/agent-improvements`, `bugfix/agent-error-handling`)
4. **Commit messages**: Clear and concise, explain the "why" not just the "what"
5. **Single-line messages**: Use only a one-line commit message with no body/description
6. **Make small commits**: Split changes into multiple small commits when possible for easier review
7. **commit by file**: If you have multiple files to change, consider committing changes file by file to keep commits focused and easier to understand
8. **Never push to remote**: Do NOT push commits to remote unless the user explicitly asks you to. Commits stay local only.
9. **Use super-commit**: When committing, use the `super-commit` command to ensure all commit rules are followed and to maintain consistency across commits
10. **Create TODOs for commits**: If you have changes that are not ready to be committed, create TODO comments in the code to track what needs to be done before committing
11. **name of commits**: Always start the commits with name of the app or directory that is being changed (e.g., "zsh: Update agent configuration" or "agent: Fix error handling in agent manager")

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
