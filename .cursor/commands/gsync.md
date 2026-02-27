--- Cursor Command: gsync ---
**Always follow these rules when generating git commits and pushing code:**

1. **Atomic Commits**

   * Break changes into the smallest possible logical units.
   * Each commit must contain *exactly one intention*.
   * Never group unrelated changes together.
   * If the user provides multiple modifications, separate them into multiple commits.

2. **Conventional Commits (in English only)**

   * Commit messages must follow:

     * `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `style:`, `perf:`, `test:`
   * The message must start with a lowercase type, a colon, and a short summary in English.
   * Use an optional body only when needed to clarify context.
   * Never write commit messages in Portuguese.
   * Do not add any trailer (e.g. `Co-authored-by`, `Signed-off-by`, etc.) or any extra line to the commit message. The message must contain *only* the conventional commit: type, optional scope, summary, and optional body when strictly needed—nothing else.
   * Use `git commit -m "type(scope): summary"` or `git commit -m "type: summary"` (e.g. `feat(api): add user login endpoint`, `fix: correct validation error`).

3. **Branch Protection**

   * Before committing, always check the current branch:
     
     ```
     git branch --show-current
     ```
   * If the current branch is `main`, `master`, or `develop`, create a new branch before committing:
     
     ```
     git checkout -b <branch-name>
     ```
   * Use descriptive branch names following the pattern: `type/description` (e.g., `feat/add-user-authentication`, `fix/resolve-login-bug`).
   * Never commit directly to `main`, `master`, or `develop` branches.

4. **Push Rules**

   * Before pushing, always synchronize with remote:
     
     ```
     git fetch --all
     git rebase
     ```
   * After rebasing, push the branch using:

     ```
     git push
     ```
   * Never use `--force` or `--force-with-lease`.

5. **General Behavior**

   * Before committing, review the diff and ensure the commit contains only the changes relevant to its message.
   * If multiple commits are needed, list them first before executing them.

6. **Return to Previous Branch**

   * After completing the task and pushing all changes, always return to the previous branch (main, master, or develop).
   * Before switching branches, remember which branch you were on initially.
   * Use the following command to return to the previous branch:
     
     ```
     git checkout <previous-branch>
     ```
   * This ensures you're ready for the next task on the main development branch.
--- End Command ---
