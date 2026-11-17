# Solution · 0.1 self-check

> Not linked from the module.

1. `-e`: exit as soon as a command fails (catches a failed `cd` followed by `rm` in the wrong folder). `-u`: an unset variable is an error (catches `rm -rf "$DIR/"` with `DIR` misspelled → would expand to `rm -rf /`). `-o pipefail`: a pipeline fails if any command in it fails, not just the last (catches `curl … | grep x` hiding a failed download). Source: https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin
2. `>` replaces the file's contents; `>>` appends. Building `errors.txt`, the ERROR lines went in with `>`, the WARN lines were added with `>>` (6 lines); re-running the `>` command replaced the whole file, so only the 4 ERROR lines remained.
3. The problem was **ownership**: root owned the file, and the permissions (`-rw-r--r--`) only let the owner write. `chmod 777` would have let *every* user on the machine write it — a security hole that hides the ownership mistake. The fix was `sudo chown "$USER": report.txt` (you become the owner; permissions unchanged).
4. `X=1; bash -c 'echo "${X:-nothing}"'` → `nothing`; after `export X` → `1`. `export` marks the variable to be copied into the environment of every child process the shell starts.
5. At `644`, other users on the machine can read the private key, so SSH treats it as compromised and refuses to use it ("UNPROTECTED PRIVATE KEY FILE"). At `600`, only you can read it. Source: https://man.openbsd.org/ssh (FILES: `~/.ssh/id_*` "should be readable only by the user")
6. Any two: relative paths (cron's working directory is your home, not the script's folder); a missing shebang (cron runs `/bin/sh`); variables or `PATH` set in your `.bashrc` that cron doesn't load; a non-exported variable a child script needs.
7. `systemctl status <service>` / `systemctl is-active <service>` (reading state — any user) and `sudo systemctl stop <service>` (changing the system — needs administrator rights, so it prompts for your password via `sudo`).
