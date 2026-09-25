---
description: Finalize a completed task, update project docs, generate a commit message, and commit the changes
---

# Wrap Task

You are finishing a unit of work in this repository.

Follow these steps in order:

1. Review the current workspace state before making edits.
- Read `tasks.md`
- Read `project_overview.md`
- Inspect staged and unstaged changes
- Inspect the git diff since the last commit
- Infer exactly what work was completed, including bug fixes, refactors, feature updates, docs changes, and configuration updates

2. Update `tasks.md`.
- Mark the single relevant completed task as done 
- If multiple subtasks were fully completed, mark only those completed subtasks as done
- Do not mark anything complete unless it is fully implemented
- Do not rewrite unrelated sections

3. Update `project_overview.md`.
- Treat this as the canonical engineering handoff document
- Add or update concise but specific notes about:
  - what changed
  - lessons learned
  - important coding patterns
  - architectural decisions
  - where important state lives
  - how data flows through the app
  - how the database works
  - any implementation gotchas
  - anything a new engineer would need to continue safely
- Be concise, but detailed enough to prevent future mistakes
- Do not add speculation or unverifiable claims
- Preserve existing useful content and improve clarity where needed

4. Prepare the git commit message.
- Write a concise but detailed GitHub commit message
- Base it on everything changed since the last commit 
- Include the most important feature work, bug fixes, refactors, and documentation updates
- Prefer a clear subject line and short bullet-style body when appropriate
- Do not omit meaningful changes

5. Commit the work.
- Stage the updated files and any other intended changes related to this task
- Use the generated commit message for the git commit
- If there are no changes to commit, do not create an empty commit and explain why
- The commands are something like git status if you need that, git add [either git add . or git add <specific files>], git commit -m "[insert commit message here]" and then git push

6. Final response.
- Respond in this exact structure:

Completed:
- Updated `tasks.md` with specific updates \
- Updated `project_overview.md` with specific updates
- Generated commit message with what the commit message is 
- Committed latest changes confirmed or it didn't work and explain why
- Finish by saying 'yes skip, we can proceed with [insert next task to proceed with]
- dont forget git push

Commit message:
```text
[insert commit message here]
