# Solution · 0.3 debugging lab — "I deleted the .env, so it's fine, right?"

> Not linked from the module. Try it first.

**Short answer: no.** The file is gone from the latest commit, but not from history, and history is what GitHub and every clone carry.

## Diagnosis path

1. **See what the latest commit shows.** `git log --oneline` lists six commits; `ls -a` shows no `.env`. A deleted file looks clean *at the tip*.
2. **Ask history, not the working folder.**
   ```bash
   git log --all --diff-filter=A --format='%h %s' -- .env     # commits that ADDED .env    -> "Add config"
   git log --all --diff-filter=D --format='%h %s' -- .env     # commits that DELETED it    -> "Remove env file"
   git log --all --format='%h %s' -S AKIAIOSFODNN7EXAMPLE      # every commit where that text appeared or vanished
   ```
   `-S` is a "pickaxe": it lists commits where the number of occurrences of the text *changed*, so it shows both the commit that added the key and the one that removed it.
3. **Read the secret from history, changing nothing.**
   ```bash
   git show <add-commit>:.env
   ```
   Replace `<add-commit>` with the short hash from step 2. The key prints in full. Deleting the file didn't delete the snapshot.
4. **Prove it's on the "remote".**
   ```bash
   git clone ~/p0-git-debug/remote.git ~/p0-git-debug/fresh
   git -C ~/p0-git-debug/fresh show <add-commit>:.env
   ```
   A brand-new clone, which knows nothing about your folder, can read it. On real GitHub, anyone who can see the repo can do the same. If the repo were public, bots scan for keys within minutes.

## The remedy, in this order

| Step | Action | Why this position |
|---|---|---|
| **(a) Revoke / rotate first** | Deactivate and delete the exposed key (for AWS: `aws iam update-access-key --status Inactive`, then `delete-access-key`), and create a new one if still needed. | The secret has to be treated as stolen the moment it was pushed. Copies already exist in clones, forks, caches and scrapers, and no history edit can recall them. Revoking is the only step that actually stops misuse. |
| **(b) Rewrite history** | Use `git filter-repo` (e.g. `git filter-repo --path .env --invert-paths`) to remove the file from every commit. **Not executed in this module; you do it in 0.4 Lab 7.** | Makes the repository clean so the secret isn't served any more, and tooling can't re-find it. Only useful *after* (a). |
| **(c) Force-push and re-clone** | `git push --force` the rewritten history to the shared remote; everyone who cloned must **re-clone** (or they'll push the old history back). Hosting providers may also keep cached views, so ask GitHub Support to purge them if the repo was public. | Rewriting changes every commit ID after the first change, so old and new histories are incompatible. |
| **(d) Prevent a repeat** | `.gitignore` for secret files, secret scanning / push protection on the repository, and a pre-commit check. Load secrets from the environment, never from files in the repo. | Cheaper than steps (a)–(c). |

Source: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

## Model `answer.md`

```
The secret .env was introduced in commit <hash> ("Add config") and removed two commits later, but it
is still in history and in a fresh clone of the remote.

1. Revoke/rotate the exposed AWS key immediately — copies may already exist, and no history rewrite can
   recall them.
2. Then rewrite history with git filter-repo --path .env --invert-paths so no commit contains the file.
3. Force-push the rewritten history to the remote; everyone who cloned must re-clone, otherwise they can
   push the old history back.
4. Prevent a repeat: add .env to .gitignore before the first commit, turn on secret scanning / push
   protection, and load secrets from the environment.
```

## Why a "wrong order" is dangerous

If you rewrite history first and feel finished, the key is still live and still sitting in every earlier clone. The rewrite makes the repository *look* safe without making the key *unusable*. Rotating first is the only step that doesn't depend on what other people have already copied.
