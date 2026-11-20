# Answers · 0.3 self-check

> Not linked from the module. Answer first.

1. **Merge** combines another branch's work into yours and keeps both histories (adding a merge commit if they had diverged); **rebase** replays your commits on top of another branch so history becomes one straight line, giving your commits new IDs.
2. `--soft` only moves the branch pointer back; your changes stay **staged**. `--mixed` (the default) also unstages them but leaves them in your files. `--hard` also **overwrites your files** to match the target commit, so the changes are gone from the working folder, not just from the commit. (Lab 5b: after `--soft`, `notes.txt` was still staged; after `--hard`, it was deleted.)
3. Ignored: `git check-ignore -v <file>` (prints the rule that matches). Not tracked: `git ls-files | grep -x <file>` prints nothing, or `git ls-files --error-unmatch <file>` fails.
4. Use `revert` when the commit is **already pushed or shared**: it adds a new commit that undoes the change, so nobody's history is rewritten. Use `reset` only on commits nobody else has.
5. `git log --diff-filter=A --format='%h %s' -- <file>` (add `--all` to search every branch).
6. (1) **Revoke/rotate** the secret, (2) clean the history with `git filter-repo`, (3) force-push and have everyone re-clone, (4) prevent a repeat. The order matters because the secret has to be treated as stolen the moment it was pushed; the rewrite can't recall copies already taken, so only revoking makes it harmless.
7. The merge is **in progress**, stopped by a conflict in `menu.txt`. Edit the file to the result you want, with all `<<<<<<<`, `=======` and `>>>>>>>` lines removed, then `git add menu.txt` and `git commit` (or `git commit --no-edit` to accept the default merge message). `git merge --abort` is the way out if you want to start over.
